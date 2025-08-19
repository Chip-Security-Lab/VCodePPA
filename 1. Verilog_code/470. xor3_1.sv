module xor3_1 (
    input wire A, B, C,
    output wire Y
);
    assign Y = A ^ B ^ C; // 3输入异或门
endmodule
