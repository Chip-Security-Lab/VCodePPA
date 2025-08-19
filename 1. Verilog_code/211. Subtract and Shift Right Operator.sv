module signed_add_shift (
    input signed [7:0] a,
    input signed [7:0] b,
    input [2:0] shift_amount,
    output signed [7:0] sum,
    output signed [7:0] shifted_result
);
    assign sum = a + b;                  // 加法
    assign shifted_result = a >>> shift_amount;  // 带符号右移
endmodule

