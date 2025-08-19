module barrel_shift #(parameter SHIFT=3, WIDTH=8) (
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
    assign data_out = {data_in, data_in} >> (WIDTH - SHIFT);
endmodule