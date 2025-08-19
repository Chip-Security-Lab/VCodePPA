module variable_step_shifter (
    input [15:0] din,
    input [1:0] step_mode,  // 00:+1, 01:+2, 10:+4
    output [15:0] dout
);
wire [3:0] shift = 1 << step_mode;
assign dout = (din << shift) | (din >> (16 - shift));
endmodule