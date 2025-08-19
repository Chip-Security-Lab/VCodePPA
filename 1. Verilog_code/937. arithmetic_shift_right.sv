module arithmetic_shift_right (
    input signed [31:0] data_in,
    input [4:0] shift,
    output signed [31:0] data_out
);
assign data_out = data_in >>> shift;  // 自动符号扩展
endmodule