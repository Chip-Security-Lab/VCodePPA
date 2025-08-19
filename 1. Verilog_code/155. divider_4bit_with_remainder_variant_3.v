module divider_4bit_with_remainder (
    input clk,
    input rst_n,
    input [3:0] dividend,
    input [3:0] divisor,
    output reg [3:0] quotient,
    output reg [3:0] remainder
);

    // 流水线寄存器
    reg [3:0] dividend_reg;
    reg [3:0] divisor_reg;
    reg [3:0] quotient_reg;
    reg [3:0] remainder_reg;

    // 输入寄存器级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dividend_reg <= 4'b0;
            divisor_reg <= 4'b0;
        end else begin
            dividend_reg <= dividend;
            divisor_reg <= divisor;
        end
    end

    // 除法运算级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient_reg <= 4'b0;
            remainder_reg <= 4'b0;
        end else begin
            quotient_reg <= dividend_reg / divisor_reg;
            remainder_reg <= dividend_reg % divisor_reg;
        end
    end

    // 输出寄存器级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient <= 4'b0;
            remainder <= 4'b0;
        end else begin
            quotient <= quotient_reg;
            remainder <= remainder_reg;
        end
    end

endmodule