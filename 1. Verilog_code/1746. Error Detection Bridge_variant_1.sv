//SystemVerilog
module error_detect_bridge #(parameter DWIDTH=32) (
    input clk, rst_n,
    input [DWIDTH-1:0] in_data,
    input in_valid,
    output reg in_ready,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid,
    output reg error,
    input out_ready
);
    // 流水线阶段信号
    reg [DWIDTH-1:0] data_stage1;
    reg valid_stage1;
    reg parity_stage1;

    // 计算奇偶校验 - 第一级流水线阶段
    reg calc_parity;

    always @(*) begin
        calc_parity = ^in_data; // 使用位异或运算符计算奇偶校验
    end

    // 第一级流水线 - 接收数据并计算校验
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            valid_stage1 <= 0;
            parity_stage1 <= 0;
        end else if (in_valid && in_ready) begin
            data_stage1 <= in_data;
            valid_stage1 <= 1'b1;
            parity_stage1 <= calc_parity;
        end else if (valid_stage1 && out_ready) begin
            valid_stage1 <= 1'b0;
        end
    end

    // 第二级流水线 - 输出数据和错误信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data <= 0;
            out_valid <= 0;
            error <= 0;
        end else if (valid_stage1) begin
            out_data <= data_stage1;
            out_valid <= 1'b1;
            error <= ~parity_stage1; // 直接使用反转逻辑计算错误信号
        end else if (out_valid && out_ready) begin
            out_valid <= 0;
            error <= 0;
        end
    end

    // 输入就绪信号控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_ready <= 1'b1;
        end else begin
            in_ready <= !valid_stage1 || out_ready;
        end
    end
endmodule