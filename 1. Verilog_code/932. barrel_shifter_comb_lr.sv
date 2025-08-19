module barrel_shifter_comb_lr (
    input [15:0] din,
    input [3:0] shift,
    output [15:0] dout
);
assign dout = din >> shift;  // 逻辑移位自动补零
endmodule