//SystemVerilog
module xor_and_or_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    // 重写表达式: C & (A ^ B) = C & A & ~B | C & ~A & B
    
    assign Y = C & ((A & ~B) | (~A & B));
endmodule