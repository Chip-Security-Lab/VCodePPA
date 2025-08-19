module xor2_3 (
    input wire [7:0] A, B,
    output wire [7:0] Y
);
    assign Y = A ^ B; // 8位宽的异或运算
endmodule
