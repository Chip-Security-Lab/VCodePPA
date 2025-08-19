//SystemVerilog
module RangeDetector_MultiMode #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input [1:0] mode,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    input valid_in,                 // 输入数据有效信号
    output ready_in,                // 输入就绪信号
    output reg valid_out,           // 输出数据有效信号
    input ready_out,                // 下游模块就绪信号
    output reg flag
);

    // 流水线寄存器和控制信号
    // Stage 1: 输入缓冲
    reg [WIDTH-1:0] data_stage1;
    reg [WIDTH-1:0] threshold_stage1;
    reg [1:0] mode_stage1;
    reg valid_stage1;
    wire stall_stage1;
    
    // Stage 2: 计算比较结果
    reg [3:0] comp_result_stage2;
    reg [1:0] mode_stage2;
    reg valid_stage2;
    wire stall_stage2;
    
    // 流水线控制逻辑
    assign stall_stage2 = valid_stage2 && !ready_out;
    assign stall_stage1 = valid_stage1 && stall_stage2;
    assign ready_in = !stall_stage1;
    
    // 第一级流水线: 输入缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            threshold_stage1 <= 0;
            mode_stage1 <= 0;
            valid_stage1 <= 0;
        end else if (!stall_stage1) begin
            data_stage1 <= data_in;
            threshold_stage1 <= threshold;
            mode_stage1 <= mode;
            valid_stage1 <= valid_in;
        end
    end

    // 第二级流水线: 并行比较逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comp_result_stage2 <= 0;
            mode_stage2 <= 0;
            valid_stage2 <= 0;
        end else if (!stall_stage2) begin
            comp_result_stage2[0] <= (data_stage1 >= threshold_stage1);
            comp_result_stage2[1] <= (data_stage1 <= threshold_stage1);
            comp_result_stage2[2] <= (data_stage1 != threshold_stage1);
            comp_result_stage2[3] <= (data_stage1 == threshold_stage1);
            mode_stage2 <= mode_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // 第三级流水线: 结果选择和输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flag <= 0;
            valid_out <= 0;
        end else if (!stall_stage2) begin
            flag <= comp_result_stage2[mode_stage2];
            valid_out <= valid_stage2;
        end
    end

endmodule