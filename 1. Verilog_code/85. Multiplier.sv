module Multiplier5(
    input clk,
    input [7:0] in_a, in_b,
    output reg [15:0] out
);
    reg [7:0] a_reg, b_reg;
    
    always @(posedge clk) begin
        a_reg <= in_a;   // 输入寄存器
        b_reg <= in_b;
        out <= a_reg * b_reg;  // 计算寄存器
    end
endmodule