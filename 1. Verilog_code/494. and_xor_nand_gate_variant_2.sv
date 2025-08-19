//SystemVerilog
module and_xor_nand_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    // 优化后的表达式
    assign Y = (A & B & C) | (~A & ~B) | (B & ~C);
endmodule