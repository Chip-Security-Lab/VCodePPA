//SystemVerilog
module xor_nand_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    // 直接实现最简表达式
    assign Y = (A ^ B) & ~C;
endmodule