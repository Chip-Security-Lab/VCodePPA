module ClkNor(input clk, a, b, output reg y);
    always @(posedge clk) y <= ~(a | b); // 寄存器输出
endmodule