//SystemVerilog
module multiclock_pattern_matcher #(parameter W = 8) (
    input clk_in, clk_out, rst_n,
    input [W-1:0] data, pattern,
    output reg match_out
);
    reg match_in_domain;
    wire [W-1:0] inverted_pattern;
    wire [W:0] subtraction_result;
    wire is_zero;
    
    // Implement 2's complement subtraction
    assign inverted_pattern = ~pattern;
    assign subtraction_result = {1'b0, data} + {1'b0, inverted_pattern} + 1'b1;
    assign is_zero = (subtraction_result[W-1:0] == {W{1'b0}});
    
    // Input clock domain
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            match_in_domain <= 1'b0;
        else
            match_in_domain <= is_zero;
    end
    
    // Output clock domain
    always @(posedge clk_out or negedge rst_n) begin
        if (!rst_n)
            match_out <= 1'b0;
        else
            match_out <= match_in_domain;
    end
endmodule