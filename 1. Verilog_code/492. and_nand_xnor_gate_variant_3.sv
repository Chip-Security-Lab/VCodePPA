//SystemVerilog
module and_nand_xnor_gate (
    input wire A, B, C, D,   // 输入A, B, C, D
    output wire Y            // 输出Y
);
    // 简化原表达式: (A & B) & ~(C & D) ~^ A
    assign Y = A ? (B & ~(C & D)) : (~A & ~(C & D));
endmodule