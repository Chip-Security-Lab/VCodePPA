//SystemVerilog
module pl_reg_dual_edge #(parameter W=8) (
    input clk, load, rstn,
    input [W-1:0] d,
    output [W-1:0] q
);
    // 流水线阶段寄存器
    reg [W-1:0] d_stage1, q_pos_stage1, q_neg_stage1;
    reg [W-1:0] d_stage2, q_pos_stage2, q_neg_stage2;
    
    // 流水线控制信号
    reg load_stage1, load_stage2;
    
    // 补码计算中间变量
    reg [W-1:0] d_complement, d_stage1_complement;
    wire [W-1:0] stage1_result, stage2_result;
    
    // 补码计算 (~x + 1)
    always @(*) begin
        d_complement = ~d + 1'b1;
        d_stage1_complement = ~d_stage1 + 1'b1;
    end
    
    // 第一级流水线 - 数据缓存
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            d_stage1 <= {W{1'b0}};
            load_stage1 <= 1'b0;
        end else begin
            d_stage1 <= d;
            load_stage1 <= load;
        end
    end
    
    // 第二级流水线 - 数据缓存
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            d_stage2 <= {W{1'b0}};
            load_stage2 <= 1'b0;
        end else begin
            d_stage2 <= d_stage1;
            load_stage2 <= load_stage1;
        end
    end
    
    // 使用补码进行减法计算
    assign stage1_result = d + d_complement;
    assign stage2_result = d_stage1 + d_stage1_complement;
    
    // 正边沿触发流水线处理
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            q_pos_stage1 <= {W{1'b0}};
            q_pos_stage2 <= {W{1'b0}};
        end else begin
            // 第一级流水线
            if (load) begin
                q_pos_stage1 <= stage1_result;
            end
            
            // 第二级流水线
            if (load_stage1) begin
                q_pos_stage2 <= stage2_result;
            end
        end
    end
    
    // 负边沿触发流水线处理
    always @(negedge clk or negedge rstn) begin
        if (!rstn) begin
            q_neg_stage1 <= {W{1'b0}};
            q_neg_stage2 <= {W{1'b0}};
        end else begin
            // 第一级流水线
            if (load) begin
                q_neg_stage1 <= stage1_result;
            end
            
            // 第二级流水线
            if (load_stage1) begin
                q_neg_stage2 <= stage2_result;
            end
        end
    end
    
    // 流水线输出多路复用
    // 使用最后一级流水线的输出
    assign q = clk ? q_pos_stage2 : q_neg_stage2;
endmodule