module nor2_conditional (
    input wire A, B,
    output wire Y
);
    assign Y = (A | B) ? 1'b0 : 1'b1;  // 条件运算符
endmodule
