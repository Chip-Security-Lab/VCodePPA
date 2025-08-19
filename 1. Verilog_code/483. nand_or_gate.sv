module nand_or_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    assign Y = ~(A & B) | C;  // 与非和或组合
endmodule
