module shift_log_right #(parameter WIDTH=8, SHIFT=2) (
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
assign data_out = data_in >> SHIFT;
endmodule
