module Cond_NAND(
    input sel,
    input [3:0] mask, data_in,
    output [3:0] data_out
);
    assign data_out = sel ? ~(data_in & mask) : data_in;
endmodule
