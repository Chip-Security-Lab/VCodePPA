module and_xnor_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    assign Y = (A & B) ~^ C;  // 与和同或组合
endmodule
