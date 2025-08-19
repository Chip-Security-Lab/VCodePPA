module Segmented_XNOR(
    input [7:0] high, low,
    output [7:0] res
);
    assign res[7:4] = ~(high[7:4] ^ low[3:0]);
    assign res[3:0] = ~(high[3:0] ^ low[7:4]);
endmodule
