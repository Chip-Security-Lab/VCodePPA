//SystemVerilog
module EdgeMatcher #(parameter WIDTH=8) (
    input clk,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] pattern,
    output reg edge_match
);
    // Split WIDTH into quarters for more balanced comparison paths
    localparam QUARTER_WIDTH = WIDTH/4;
    
    // Input pipeline registers
    reg [WIDTH-1:0] data_in_reg;
    reg [WIDTH-1:0] pattern_reg;
    
    // Intermediate comparison results for each quarter
    reg comp_q1, comp_q2, comp_q3, comp_q4;
    
    // Combined comparison results
    reg comp_upper, comp_lower;
    reg match_result;
    
    // Edge detection registers
    reg last_match;
    
    always @(posedge clk) begin
        // First pipeline stage - register inputs
        data_in_reg <= data_in;
        pattern_reg <= pattern;
        
        // Second pipeline stage - parallel quarter comparisons
        // This creates a more balanced tree of comparisons
        comp_q1 <= (data_in_reg[WIDTH-1:3*QUARTER_WIDTH] == pattern_reg[WIDTH-1:3*QUARTER_WIDTH]);
        comp_q2 <= (data_in_reg[3*QUARTER_WIDTH-1:2*QUARTER_WIDTH] == pattern_reg[3*QUARTER_WIDTH-1:2*QUARTER_WIDTH]);
        comp_q3 <= (data_in_reg[2*QUARTER_WIDTH-1:QUARTER_WIDTH] == pattern_reg[2*QUARTER_WIDTH-1:QUARTER_WIDTH]);
        comp_q4 <= (data_in_reg[QUARTER_WIDTH-1:0] == pattern_reg[QUARTER_WIDTH-1:0]);
        
        // Third pipeline stage - combine quarters into halves
        comp_upper <= comp_q1 & comp_q2;
        comp_lower <= comp_q3 & comp_q4;
        
        // Fourth pipeline stage - final match result
        match_result <= comp_upper & comp_lower;
        
        // Fifth pipeline stage - edge detection
        last_match <= match_result;
        edge_match <= match_result & ~last_match;
    end
endmodule