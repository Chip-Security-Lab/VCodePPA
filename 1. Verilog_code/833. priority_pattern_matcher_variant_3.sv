//SystemVerilog
module priority_pattern_matcher #(
    parameter WIDTH = 8,
    parameter PATTERNS = 4
)(
    input                               clk,
    input                               rst_n,
    input      [WIDTH-1:0]              data_in,
    input      [WIDTH-1:0]              patterns [PATTERNS-1:0],
    output reg [($clog2(PATTERNS))-1:0] match_idx,
    output reg                          match_found
);
    // Stage 1: Pattern comparison registers
    reg [PATTERNS-1:0] pattern_match_stage1;
    
    // Stage 2: Priority encoding pipeline registers
    reg [PATTERNS-1:0] pattern_match_stage2;
    reg                valid_stage2;
    
    // Pattern comparison logic - Stage 1
    genvar i;
    generate
        for (i = 0; i < PATTERNS; i = i + 1) begin : pattern_compare
            wire [WIDTH-1:0] diff;
            wire borrow;
            
            // Borrow subtractor implementation
            assign {borrow, diff} = {1'b0, data_in} - {1'b0, patterns[i]};
            assign pattern_match_stage1[i] = ~|diff;
        end
    endgenerate
    
    // Priority encoding preparation - Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern_match_stage2 <= {PATTERNS{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            pattern_match_stage2 <= pattern_match_stage1;
            valid_stage2 <= |pattern_match_stage1;
        end
    end
    
    // Priority encoding and output generation - Final Stage
    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_idx <= {($clog2(PATTERNS)){1'b0}};
            match_found <= 1'b0;
        end else begin
            match_found <= valid_stage2;
            
            // Default assignment
            match_idx <= match_idx;
            
            // Priority encoding (highest index has priority)
            if (valid_stage2) begin
                for (j = PATTERNS-1; j >= 0; j = j - 1) begin
                    if (pattern_match_stage2[j]) begin
                        match_idx <= j;
                    end
                end
            end
        end
    end
endmodule