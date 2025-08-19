module Comparator_Window #(parameter WIDTH = 10) (
    input  [WIDTH-1:0] data_in,
    input  [WIDTH-1:0] low_th,
    input  [WIDTH-1:0] high_th,
    output             in_range
);
    assign in_range = (data_in >= low_th) && 
                     (data_in <= high_th);
endmodule