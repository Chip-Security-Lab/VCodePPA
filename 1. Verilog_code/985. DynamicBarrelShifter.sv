module DynamicBarrelShifter #(parameter MAX_SHIFT=4, WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input [MAX_SHIFT-1:0] shift_val,
    output [WIDTH-1:0] data_out
);
assign data_out = data_in << shift_val;
endmodule