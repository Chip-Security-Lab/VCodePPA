//SystemVerilog
//IEEE 1364-2005 Verilog
// Top level module
module and_xor_not_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    // 直接实现布尔表达式: Y = (A&B^C) & (~A)
    // 使用德摩根定律和布尔代数简化: Y = (A&B&~C) | (~A&B&C)
    assign Y = (~A & B & C) | (A & B & ~C);
endmodule