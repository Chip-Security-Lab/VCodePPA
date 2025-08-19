module shift_xor_operator (
    input [7:0] a,
    input [2:0] shift_amount,
    output [7:0] shifted_result,
    output [7:0] xor_result
);
    assign shifted_result = a >> shift_amount;  // 右移
    assign xor_result = a ^ shifted_result;     // 异或
endmodule
