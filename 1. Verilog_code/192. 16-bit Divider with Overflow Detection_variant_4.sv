//SystemVerilog
module divider_16bit (
    input [15:0] dividend,
    input [15:0] divisor,
    output reg [15:0] quotient,
    output reg [15:0] remainder,
    output reg overflow
);

always @(*) begin
    // 使用多路复用器结构实现条件选择
    overflow = (divisor == 0) ? 1'b1 : 1'b0;

    // 显式多路复用器实现
    case (divisor == 0)
        1'b1: begin
            quotient = 16'b0;
            remainder = 16'b0;
        end
        1'b0: begin
            quotient = dividend / divisor;
            remainder = dividend % divisor;
        end
    endcase
end

endmodule