module subtract_shift_right (
    input [7:0] a,
    input [7:0] b,
    input [2:0] shift_amount,
    output [7:0] difference,
    output [7:0] shifted_result
);
    assign difference = a - b;               // 减法
    assign shifted_result = a >> shift_amount; // 右移
endmodule
