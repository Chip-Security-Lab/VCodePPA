module Shifter_NAND(
    input [2:0] shift,
    input [7:0] val,
    output [7:0] res
);
    assign res = ~(val & (8'hFF << shift));
endmodule
