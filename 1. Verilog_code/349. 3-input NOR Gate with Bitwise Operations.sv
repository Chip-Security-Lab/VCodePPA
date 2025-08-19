module nor3_bitwise (
    input wire [2:0] A,  // 3 位输入
    output wire Y
);
    assign Y = ~(A[0] | A[1] | A[2]);  // 使用按位操作
endmodule
