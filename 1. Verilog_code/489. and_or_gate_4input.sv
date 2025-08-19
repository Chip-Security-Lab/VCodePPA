module and_or_gate_4input (
    input wire A, B, C, D,   // 四个输入
    output wire Y            // 输出Y
);
    assign Y = (A & B) | (C & D);  // 四输入与或组合
endmodule
