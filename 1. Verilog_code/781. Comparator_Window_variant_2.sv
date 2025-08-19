//SystemVerilog
module Comparator_Window #(parameter WIDTH = 10) (
    input  [WIDTH-1:0] data_in,
    input  [WIDTH-1:0] low_th,
    input  [WIDTH-1:0] high_th,
    output             in_range
);
    wire [WIDTH-1:0] diff_low, diff_high;
    wire            above_low, below_high;
    
    assign diff_low  = data_in - low_th;
    assign diff_high = high_th - data_in;
    
    assign above_low = ~diff_low[WIDTH-1];
    assign below_high = ~diff_high[WIDTH-1];
    
    assign in_range = above_low & below_high;
endmodule