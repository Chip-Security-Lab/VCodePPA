module Multiplier1(
    input [7:0] a, b,
    output reg [15:0] result
);
    always @(*) begin
        result = a * b;  // 直接使用乘法运算符
    end
endmodule