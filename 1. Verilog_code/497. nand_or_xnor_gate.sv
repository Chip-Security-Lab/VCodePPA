module nand_or_xnor_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    assign Y = ~(A & B) | (C ~^ A);  // 与非、或和同或组合
endmodule
