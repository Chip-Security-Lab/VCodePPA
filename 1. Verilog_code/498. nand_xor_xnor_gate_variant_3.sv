//SystemVerilog
//IEEE 1364-2005 Verilog
module nand_xor_xnor_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    // 原表达式: ~(A & B) ^ (C ~^ A)
    // 更优化的表达式
    assign Y = A ? (~B ^ ~C) : (~B ^ C);
endmodule