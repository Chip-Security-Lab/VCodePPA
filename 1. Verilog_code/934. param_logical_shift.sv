module param_logical_shift #(
    parameter WIDTH = 16,
    parameter SHIFT_W = $clog2(WIDTH)
)(
    input signed [WIDTH-1:0] din,
    input [SHIFT_W-1:0] shift,
    output signed [WIDTH-1:0] dout
);
assign dout = din <<< shift;  // 自动处理符号扩展
endmodule