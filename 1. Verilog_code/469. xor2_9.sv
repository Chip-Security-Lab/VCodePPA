module xor2_9 (
    input wire A, B,
    output wire Y
);
    assign Y = (A << 1) ^ (B >> 1); // 使用移位操作与异或门
endmodule
