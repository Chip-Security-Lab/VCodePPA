module nor2_inline (
    input wire A, B,
    output Y
);
    assign Y = ~(A | B);  // 简单的或非门
endmodule
