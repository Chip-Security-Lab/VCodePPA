module xor2_5 (
    input wire A, B, C, D,
    output wire Y
);
    assign Y = A ^ B ^ C ^ D; // 4输入异或门
endmodule
