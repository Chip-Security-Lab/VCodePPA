module multiclock_pattern_matcher #(parameter W = 8) (
    input clk_in, clk_out, rst_n,
    input [W-1:0] data, pattern,
    output reg match_out
);
    reg match_in_domain;
    
    // Input clock domain
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            match_in_domain <= 1'b0;
        else
            match_in_domain <= (data == pattern);
    end
    
    // Output clock domain
    always @(posedge clk_out or negedge rst_n) begin
        if (!rst_n)
            match_out <= 1'b0;
        else
            match_out <= match_in_domain;
    end
endmodule