//SystemVerilog
module range_pattern_matcher #(parameter WIDTH = 8) (
    input clk, rst_n,
    input [WIDTH-1:0] data, lower_bound, upper_bound,
    output reg in_range
);
    // Pre-compute comparison results to reduce critical path
    wire lower_compare, upper_compare;
    
    // Optimize comparison logic by using dedicated comparators
    assign lower_compare = (data >= lower_bound);
    assign upper_compare = (data <= upper_bound);
    
    // Combine results in the sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            in_range <= 1'b0;
        else
            in_range <= lower_compare && upper_compare;
    end
endmodule