//SystemVerilog
module history_pattern_matcher #(parameter W = 8, DEPTH = 3) (
    input clk, rst_n,
    input [W-1:0] data_in, pattern,
    output reg seq_match
);

    // Pipeline stage 1: History shift and input capture
    reg [W-1:0] history_stage1 [DEPTH-1:0];
    reg [W-1:0] pattern_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2: Pattern matching
    reg [W-1:0] history_stage2;
    reg [W-1:0] pattern_stage2;
    reg valid_stage2;
    
    integer i;
    
    // Stage 1: History shift and input capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1)
                history_stage1[i] <= 0;
            pattern_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            // Shift history register
            for (i = DEPTH-1; i > 0; i = i - 1)
                history_stage1[i] <= history_stage1[i-1];
            history_stage1[0] <= data_in;
            
            // Capture pattern and set valid
            pattern_stage1 <= pattern;
            valid_stage1 <= 1;
        end
    end
    
    // Stage 2: Pattern matching
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            history_stage2 <= 0;
            pattern_stage2 <= 0;
            valid_stage2 <= 0;
            seq_match <= 0;
        end else begin
            // Pass through history and pattern
            history_stage2 <= history_stage1[0];
            pattern_stage2 <= pattern_stage1;
            valid_stage2 <= valid_stage1;
            
            // Perform pattern matching
            seq_match <= valid_stage2 && (history_stage2 == pattern_stage2);
        end
    end
endmodule