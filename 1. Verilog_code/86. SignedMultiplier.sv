module SignedMultiplier(
    input signed [7:0] a, b,
    output signed [15:0] result
);
    assign result = a * b;  // 带符号计算
endmodule