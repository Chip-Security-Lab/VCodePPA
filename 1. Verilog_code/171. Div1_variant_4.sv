//SystemVerilog
module Div1(
    input logic clk,
    input logic rst_n,
    input logic [7:0] dividend,
    input logic [7:0] divisor,
    output logic [7:0] quotient
);

    // 流水线寄存器
    logic [7:0] dividend_reg;
    logic [7:0] divisor_reg;
    logic [7:0] quotient_reg;
    logic div_valid_reg;

    // 控制信号
    logic div_valid;

    // 数据路径
    logic [7:0] div_result;

    // 输入寄存器级
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dividend_reg <= 8'h0;
            divisor_reg <= 8'h0;
        end else begin
            dividend_reg <= dividend;
            divisor_reg <= divisor;
        end
    end

    // 除法运算级
    assign div_valid = |divisor_reg;
    assign div_result = dividend_reg / divisor_reg;

    // 输出寄存器级
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient_reg <= 8'h0;
            div_valid_reg <= 1'b0;
        end else begin
            quotient_reg <= div_valid ? div_result : 8'hFF;
            div_valid_reg <= div_valid;
        end
    end

    // 输出
    assign quotient = quotient_reg;

endmodule