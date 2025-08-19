//SystemVerilog
module multiclock_pattern_matcher #(parameter W = 8) (
    input clk_in, clk_out, rst_n,
    input [W-1:0] data, pattern,
    output reg match_out
);
    // Input domain signals
    reg [W-1:0] data_reg;
    reg [W-1:0] pattern_reg;
    reg match_in_domain;
    
    // Intermediate comparison signals to balance paths
    reg [3:0] match_upper, match_lower;
    
    // Synchronization registers for clock domain crossing
    reg match_sync1;
    reg match_sync2;
    
    // ========== INPUT CLOCK DOMAIN ==========
    // Register inputs to improve timing
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= {W{1'b0}};
            pattern_reg <= {W{1'b0}};
        end else begin
            data_reg <= data;
            pattern_reg <= pattern;
        end
    end
    
    // Balanced pattern matching logic with parallel comparisons
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            match_upper <= 4'b0;
            match_lower <= 4'b0;
            match_in_domain <= 1'b0;
        end else begin
            // Split comparison into balanced parallel paths
            match_upper[0] <= (data_reg[7] == pattern_reg[7]);
            match_upper[1] <= (data_reg[6] == pattern_reg[6]);
            match_upper[2] <= (data_reg[5] == pattern_reg[5]);
            match_upper[3] <= (data_reg[4] == pattern_reg[4]);
            
            match_lower[0] <= (data_reg[3] == pattern_reg[3]);
            match_lower[1] <= (data_reg[2] == pattern_reg[2]);
            match_lower[2] <= (data_reg[1] == pattern_reg[1]);
            match_lower[3] <= (data_reg[0] == pattern_reg[0]);
            
            // Combine results in a balanced tree structure
            match_in_domain <= &{match_upper, match_lower};
        end
    end
    
    // ========== OUTPUT CLOCK DOMAIN ==========
    // Two-stage synchronizer to prevent metastability
    always @(posedge clk_out or negedge rst_n) begin
        if (!rst_n) begin
            match_sync1 <= 1'b0;
            match_sync2 <= 1'b0;
            match_out <= 1'b0;
        end else begin
            match_sync1 <= match_in_domain;
            match_sync2 <= match_sync1;
            match_out <= match_sync2;
        end
    end
endmodule