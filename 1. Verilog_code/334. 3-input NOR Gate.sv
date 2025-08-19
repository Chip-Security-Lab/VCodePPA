module nor4 (
    input wire A, B, C, D,
    output wire Y
);
    assign Y = ~(A | B | C | D);  // 四输入的或非门
endmodule
