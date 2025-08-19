//SystemVerilog
module history_pattern_matcher #(parameter W = 8, DEPTH = 3) (
    input clk, rst_n,
    input [W-1:0] data_in, pattern,
    output reg seq_match
);
    reg [W-1:0] history [DEPTH-1:0];
    reg [W-1:0] history_shifted [DEPTH-1:0];
    wire [W-1:0] pattern_match;
    
    // Parallel pattern matching
    assign pattern_match = history[0] ^ pattern;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < DEPTH; i = i + 1) begin
                history[i] <= '0;
                history_shifted[i] <= '0;
            end
            seq_match <= 1'b0;
        end else begin
            // Parallel shift operation
            for (integer i = 0; i < DEPTH-1; i = i + 1)
                history_shifted[i+1] <= history[i];
            history_shifted[0] <= data_in;
            
            // Update history in parallel
            for (integer i = 0; i < DEPTH; i = i + 1)
                history[i] <= history_shifted[i];
            
            // Optimized pattern matching
            seq_match <= ~|pattern_match;
        end
    end
endmodule