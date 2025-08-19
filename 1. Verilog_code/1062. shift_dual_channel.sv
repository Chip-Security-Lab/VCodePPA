module shift_dual_channel #(parameter WIDTH=8) (
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] left_out,
    output [WIDTH-1:0] right_out
);
assign left_out = din << 1;
assign right_out = din >> 1;
endmodule
