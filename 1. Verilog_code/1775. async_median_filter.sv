module async_median_filter #(
    parameter W = 16
)(
    input [W-1:0] a, b, c,
    output [W-1:0] med_out
);
    wire [W-1:0] min_ab, max_ab, result;
    
    // Find min and max between a and b
    assign min_ab = (a < b) ? a : b;
    assign max_ab = (a > b) ? a : b;
    
    // Median is max(min(a,b), min(max(a,b), c))
    assign result = (c < min_ab) ? min_ab : 
                   ((c > max_ab) ? max_ab : c);
    assign med_out = result;
endmodule