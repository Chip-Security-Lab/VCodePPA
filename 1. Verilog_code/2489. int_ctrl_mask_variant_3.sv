//SystemVerilog
module int_ctrl_mask #(
    parameter DW = 16
)(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire valid_in,
    input wire [DW-1:0] req_in,
    input wire [DW-1:0] mask,
    output reg [DW-1:0] masked_req,
    output reg valid_out,
    // 添加流水线控制信号
    input wire flush,                // 流水线刷新信号
    output wire ready_in,            // 输入就绪信号
    input wire ready_out,            // 下游模块就绪信号
    output wire [2:0] pipeline_status // 流水线状态指示
);

    // 流水线阶段控制信号
    reg [2:0] valid_stages;          // 各阶段有效信号
    wire [2:0] stage_ready;          // 各阶段就绪信号
    
    // 流水线第一级：输入寄存
    reg [DW-1:0] req_stage1;
    reg [DW-1:0] mask_stage1;
    
    // 流水线第二级：掩码分解与预处理
    reg [DW-1:0] req_stage2;
    reg [DW-1:0] mask_decomp_stage2; // 掩码分解预处理
    
    // 流水线第三级：掩码应用和结果处理
    reg [DW-1:0] masked_req_stage3;
    
    // 流水线状态信号
    assign pipeline_status = valid_stages;
    
    // 反压控制逻辑
    assign stage_ready[2] = ready_out || !valid_stages[2];
    assign stage_ready[1] = stage_ready[2] || !valid_stages[1];
    assign stage_ready[0] = stage_ready[1] || !valid_stages[0];
    assign ready_in = stage_ready[0] && en;
    
    // 第一级流水线 - 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_stage1 <= {DW{1'b0}};
            mask_stage1 <= {DW{1'b0}};
            valid_stages[0] <= 1'b0;
        end 
        else if (flush) begin
            valid_stages[0] <= 1'b0;
        end
        else if (en && stage_ready[0]) begin
            req_stage1 <= req_in;
            mask_stage1 <= mask;
            valid_stages[0] <= valid_in;
        end
    end

    // 第二级流水线 - 掩码分解与预处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_stage2 <= {DW{1'b0}};
            mask_decomp_stage2 <= {DW{1'b0}};
            valid_stages[1] <= 1'b0;
        end 
        else if (flush) begin
            valid_stages[1] <= 1'b0;
        end
        else if (en && stage_ready[1]) begin
            req_stage2 <= req_stage1;
            // 掩码预处理，可以在这里实现掩码优化策略
            mask_decomp_stage2 <= ~mask_stage1; // 预先计算取反值
            valid_stages[1] <= valid_stages[0];
        end
    end

    // 第三级流水线 - 掩码应用和结果处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_req_stage3 <= {DW{1'b0}};
            valid_stages[2] <= 1'b0;
        end 
        else if (flush) begin
            valid_stages[2] <= 1'b0;
        end
        else if (en && stage_ready[2]) begin
            // 直接使用预处理的取反掩码进行与操作
            masked_req_stage3 <= req_stage2 & mask_decomp_stage2;
            valid_stages[2] <= valid_stages[1];
        end
    end

    // 输出赋值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_req <= {DW{1'b0}};
            valid_out <= 1'b0;
        end 
        else if (flush) begin
            valid_out <= 1'b0;
        end
        else if (en && ready_out) begin
            masked_req <= masked_req_stage3;
            valid_out <= valid_stages[2];
        end
    end

endmodule