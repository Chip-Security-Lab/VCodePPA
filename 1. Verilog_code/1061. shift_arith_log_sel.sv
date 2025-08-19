module shift_arith_log_sel #(parameter WIDTH=8) (
    input mode, // 0-logical, 1-arithmetic
    input [WIDTH-1:0] din,
    input [2:0] shift,
    output [WIDTH-1:0] dout
);
assign dout = mode ? ($signed(din) >>> shift) : (din >> shift);
endmodule
