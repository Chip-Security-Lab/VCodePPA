module xor2_18 (
    input wire A, B,
    output wire Y
);
    assign Y = A ^ B; // 使用内置的`^`符号实现异或
endmodule
