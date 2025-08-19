module Comparator_Approximate #(
    parameter WIDTH = 10,
    parameter THRESHOLD = 3 // 最大允许差值
)(
    input  [WIDTH-1:0] data_p,
    input  [WIDTH-1:0] data_q,
    output             approx_eq
);
    wire [WIDTH-1:0] diff = (data_p > data_q) ? 
                           (data_p - data_q) : 
                           (data_q - data_p);
    
    assign approx_eq = (diff <= THRESHOLD);
endmodule