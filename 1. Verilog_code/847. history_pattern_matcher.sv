module history_pattern_matcher #(parameter W = 8, DEPTH = 3) (
    input clk, rst_n,
    input [W-1:0] data_in, pattern,
    output reg seq_match
);
    reg [W-1:0] history [DEPTH-1:0];
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1)
                history[i] <= 0;
            seq_match <= 0;
        end else begin
            // Shift history register
            for (i = DEPTH-1; i > 0; i = i - 1)
                history[i] <= history[i-1];
            history[0] <= data_in;
            
            // Check if most recent entry matches pattern
            seq_match <= (history[0] == pattern);
        end
    end
endmodule