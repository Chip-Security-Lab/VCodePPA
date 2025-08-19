//SystemVerilog
module vector_ismu #(parameter VECTOR_WIDTH = 8)(
    input wire clk_i, rst_n_i,
    input wire [VECTOR_WIDTH-1:0] src_i,
    input wire [VECTOR_WIDTH-1:0] mask_i,
    input wire ack_i,
    output reg [VECTOR_WIDTH-1:0] vector_o,
    output reg valid_o,
    // 流水线控制信号
    input wire ready_i,
    output reg ready_o
);
    // 流水线第一级寄存器
    reg [VECTOR_WIDTH-1:0] src_stage1;
    reg [VECTOR_WIDTH-1:0] mask_stage1;
    reg valid_stage1;
    
    // 流水线第二级寄存器
    reg [VECTOR_WIDTH-1:0] masked_src_stage2;
    reg valid_stage2;
    
    // 流水线第三级寄存器
    reg [VECTOR_WIDTH-1:0] pending_r;
    reg [VECTOR_WIDTH-1:0] vector_stage3;
    reg valid_stage3;
    
    // 流水线控制信号
    wire stall;
    wire pipeline_ready;
    
    // 简化控制逻辑，分解赋值
    assign stall = valid_o && !ack_i;
    assign pipeline_ready = !stall;
    
    // 第一级流水线：输入寄存
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            src_stage1 <= {VECTOR_WIDTH{1'b0}};
            mask_stage1 <= {VECTOR_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end 
        else begin
            if (pipeline_ready) begin
                if (ready_i) begin
                    src_stage1 <= src_i;
                    mask_stage1 <= mask_i;
                    valid_stage1 <= 1'b1;
                end
                else begin
                    valid_stage1 <= 1'b0;
                end
            end
        end
    end
    
    // 第二级流水线：计算掩码
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            masked_src_stage2 <= {VECTOR_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end 
        else begin
            if (pipeline_ready) begin
                masked_src_stage2 <= src_stage1 & ~mask_stage1;
                valid_stage2 <= valid_stage1;
            end
        end
    end
    
    // 第三级流水线：Pending状态更新
    reg [VECTOR_WIDTH-1:0] next_pending;
    reg has_new_data;
    reg [VECTOR_WIDTH-1:0] combined_vector;
    
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            pending_r <= {VECTOR_WIDTH{1'b0}};
            vector_stage3 <= {VECTOR_WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end 
        else begin
            if (pipeline_ready) begin
                // 确定新数据是否有效
                has_new_data = valid_stage2 && (|masked_src_stage2);
                
                // 计算下一个pending值
                if (ack_i) begin
                    next_pending = has_new_data ? masked_src_stage2 : {VECTOR_WIDTH{1'b0}};
                end
                else begin
                    next_pending = pending_r | (has_new_data ? masked_src_stage2 : {VECTOR_WIDTH{1'b0}});
                end
                
                // 更新pending寄存器
                pending_r <= next_pending;
                
                // 计算组合后的向量值
                combined_vector = has_new_data ? (pending_r | masked_src_stage2) : pending_r;
                
                // 更新第三级流水线寄存器
                valid_stage3 <= (|pending_r) || has_new_data;
                vector_stage3 <= combined_vector;
            end
        end
    end
    
    // 输出级
    reg next_valid;
    
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            vector_o <= {VECTOR_WIDTH{1'b0}};
            valid_o <= 1'b0;
            ready_o <= 1'b1;
        end 
        else begin
            // 计算下一个valid状态
            if (ack_i) begin
                next_valid = 1'b0;
            end
            else if (pipeline_ready) begin
                next_valid = valid_stage3;
            end
            else begin
                next_valid = valid_o;
            end
            
            // 更新输出寄存器
            valid_o <= next_valid;
            
            if (pipeline_ready) begin
                vector_o <= vector_stage3;
            end
            
            ready_o <= pipeline_ready;
        end
    end
endmodule