//SystemVerilog
module xor2_9 (
    input wire A, B,
    output wire Y
);
    // 直接使用异或操作，避免不必要的移位运算
    assign Y = A ^ B;
endmodule