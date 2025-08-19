module shift_mux_based #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input [$clog2(WIDTH)-1:0] shift_amt,
    output [WIDTH-1:0] data_out
);
assign data_out = data_in << shift_amt;
endmodule
