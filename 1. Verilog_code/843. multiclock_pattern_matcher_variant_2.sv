//SystemVerilog
module multiclock_pattern_matcher #(parameter W = 8) (
    input clk_in, clk_out, rst_n,
    input [W-1:0] data, pattern,
    output reg match_out
);
    reg match_in_domain;
    wire [W-1:0] diff;
    wire all_zeros;
    
    // Conditional complement subtractor implementation
    wire [W:0] complement_result;
    wire [W-1:0] pattern_complement;
    wire [W-1:0] data_complement;
    wire [W-1:0] final_result;
    wire borrow;
    
    // Generate complements
    assign pattern_complement = ~pattern;
    assign data_complement = ~data;
    
    // Conditional complement subtraction
    assign {borrow, final_result} = (data >= pattern) ? 
        {1'b0, data - pattern} : 
        {1'b1, pattern_complement + data + 1'b1};
    
    assign diff = final_result;
    
    // Check if all bits are zero (indicates equality)
    assign all_zeros = ~|diff;
    
    // Input clock domain
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            match_in_domain <= 1'b0;
        else
            match_in_domain <= all_zeros;
    end
    
    // Output clock domain
    always @(posedge clk_out or negedge rst_n) begin
        if (!rst_n)
            match_out <= 1'b0;
        else
            match_out <= match_in_domain;
    end
endmodule