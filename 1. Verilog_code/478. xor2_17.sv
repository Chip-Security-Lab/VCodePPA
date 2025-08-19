module xor2_17 (
    input wire A, B, C, D,
    output wire Y
);
    wire tmp1, tmp2;
    assign tmp1 = A ^ B;
    assign tmp2 = C ^ D;
    assign Y = tmp1 ^ tmp2; // 两级异或门
endmodule
