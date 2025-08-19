module xor2_12 (
    input wire [3:0] A, B,
    output wire [3:0] Y
);
    assign Y = A ^ B; // 4位数组输入的异或门
endmodule
