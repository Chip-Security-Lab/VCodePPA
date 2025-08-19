module and_nand_xnor_gate (
    input wire A, B, C, D,   // 输入A, B, C, D
    output wire Y            // 输出Y
);
    assign Y = (A & B) & ~(C & D) ~^ A;  // 与、与非和同或组合
endmodule
