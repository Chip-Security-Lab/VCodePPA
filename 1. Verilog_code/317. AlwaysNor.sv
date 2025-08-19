module AlwaysNor(input a, b, output reg y);
    always @(*) y = ~(a | b); // 过程赋值
endmodule