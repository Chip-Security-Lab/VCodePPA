//SystemVerilog
module Segmented_XNOR(
    input [7:0] high, low,
    output [7:0] res
);
    // XNOR can be expressed directly using equality comparison
    // This achieves the same function with clearer intent
    assign res[7:4] = (high[7:4] == low[3:0]) ? 4'b1111 : 4'b0000;
    assign res[3:0] = (high[3:0] == low[7:4]) ? 4'b1111 : 4'b0000;
endmodule