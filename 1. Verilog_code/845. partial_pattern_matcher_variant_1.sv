//SystemVerilog
module partial_pattern_matcher #(
    parameter W = 16,
    parameter SLICE = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [W-1:0] data,
    input wire [W-1:0] pattern,
    input wire match_upper,
    output reg match_result
);
    // Pipeline stage 1: Register inputs
    reg [W-1:0] data_reg, pattern_reg;
    reg match_upper_reg;
    
    // First pipeline stage: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= {W{1'b0}};
            pattern_reg <= {W{1'b0}};
            match_upper_reg <= 1'b0;
        end else begin
            data_reg <= data;
            pattern_reg <= pattern;
            match_upper_reg <= match_upper;
        end
    end
    
    // Pipeline stage 2: Calculate matches and select result
    reg upper_match, lower_match;
    reg match_upper_reg2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            upper_match <= 1'b0;
            lower_match <= 1'b0;
            match_upper_reg2 <= 1'b0;
            match_result <= 1'b0;
        end else begin
            // Calculate pattern matches
            upper_match <= (data_reg[W-1:W-SLICE] == pattern_reg[W-1:W-SLICE]);
            lower_match <= (data_reg[SLICE-1:0] == pattern_reg[SLICE-1:0]);
            match_upper_reg2 <= match_upper_reg;
            // Select match result
            match_result <= match_upper_reg2 ? upper_match : lower_match;
        end
    end
endmodule