module xor2_10 (
    input wire A, B,
    output wire Y
);
    assign Y = ~(A ^ B); // 通过异或门模拟NAND
endmodule
