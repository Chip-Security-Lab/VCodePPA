module and_not_gate (
    input wire A, B,   // 输入A, B
    output wire Y     // 输出Y
);
    assign Y = (A & B) & ~A;  // 与门和非门组合
endmodule
