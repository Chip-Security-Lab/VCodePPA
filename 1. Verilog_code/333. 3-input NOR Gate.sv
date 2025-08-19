module nor3 (
    input wire A, B, C,
    output wire Y
);
    assign Y = ~(A | B | C);  // 三个输入的或运算取反
endmodule
