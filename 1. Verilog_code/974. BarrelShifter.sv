module BarrelShifter #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input [3:0] shift_ctrl,
    output [WIDTH-1:0] data_out
);
assign data_out = data_in << shift_ctrl;
endmodule