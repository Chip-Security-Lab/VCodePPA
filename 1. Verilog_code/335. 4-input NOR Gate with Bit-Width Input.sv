module nor4_bits (
    input wire [3:0] A,  // 4 位输入
    output wire Y
);
    assign Y = ~(A[0] | A[1] | A[2] | A[3]);  // 或非运算
endmodule
