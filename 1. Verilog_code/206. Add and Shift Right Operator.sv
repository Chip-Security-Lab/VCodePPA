module add_shift_right (
    input [7:0] a,
    input [7:0] b,
    input [2:0] shift_amount,
    output [7:0] sum,
    output [7:0] shifted_result
);
    assign sum = a + b;                // 加法
    assign shifted_result = a >> shift_amount; // 右移
endmodule

