//SystemVerilog
module configurable_matcher #(parameter DW = 8) (
    input clk, rst_n,
    input [DW-1:0] data, pattern,
    input [1:0] mode, // 00: equality, 01: greater, 10: less, 11: not equal
    output reg result
);
    // Pre-compute comparison results combinationally
    wire equal, greater, less;
    wire not_equal;
    
    assign equal = (data == pattern);
    assign greater = (data > pattern);
    assign less = (data < pattern);
    assign not_equal = ~equal;
    
    // Use registered comparison results
    reg [3:0] comparison_results;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comparison_results <= 4'b0;
        end else begin
            comparison_results <= {not_equal, less, greater, equal};
        end
    end
    
    // Use indexed select for better optimization opportunity
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            result <= 1'b0;
        else
            result <= comparison_results[mode];
    end
endmodule