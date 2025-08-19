//SystemVerilog
module multi_enable_matcher #(parameter DW = 8) (
    input clk, rst_n,
    input [DW-1:0] data, pattern,
    input en_capture, en_compare,
    output reg match
);
    // Stage 1 registers
    reg [DW-1:0] stored_data_stage1;
    reg [DW-1:0] pattern_stage1;
    reg en_capture_stage1;
    reg en_compare_stage1;
    
    // Stage 2 registers
    reg [DW-1:0] stored_data_stage2;
    reg [DW-1:0] pattern_stage2;
    reg en_compare_stage2;
    wire [DW-1:0] data_xor_pattern_stage2;
    
    // Stage 3 registers
    reg [DW-1:0] data_xor_pattern_stage3;
    reg en_compare_stage3;
    wire match_comb_stage3;
    
    // Stage 4 registers
    reg match_precompute_stage4;
    reg en_compare_stage4;
    
    // Combinational logic
    assign data_xor_pattern_stage2 = stored_data_stage2 ^ pattern_stage2;
    assign match_comb_stage3 = ~(|data_xor_pattern_stage3);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Stage 1 reset
            stored_data_stage1 <= {DW{1'b0}};
            pattern_stage1 <= {DW{1'b0}};
            en_capture_stage1 <= 1'b0;
            en_compare_stage1 <= 1'b0;
            
            // Stage 2 reset
            stored_data_stage2 <= {DW{1'b0}};
            pattern_stage2 <= {DW{1'b0}};
            en_compare_stage2 <= 1'b0;
            
            // Stage 3 reset
            data_xor_pattern_stage3 <= {DW{1'b0}};
            en_compare_stage3 <= 1'b0;
            
            // Stage 4 reset
            match_precompute_stage4 <= 1'b0;
            en_compare_stage4 <= 1'b0;
            
            // Output reset
            match <= 1'b0;
        end else begin
            // Stage 1 pipeline
            if (en_capture)
                stored_data_stage1 <= data;
            pattern_stage1 <= pattern;
            en_capture_stage1 <= en_capture;
            en_compare_stage1 <= en_compare;
            
            // Stage 2 pipeline
            stored_data_stage2 <= stored_data_stage1;
            pattern_stage2 <= pattern_stage1;
            en_compare_stage2 <= en_compare_stage1;
            
            // Stage 3 pipeline
            data_xor_pattern_stage3 <= data_xor_pattern_stage2;
            en_compare_stage3 <= en_compare_stage2;
            
            // Stage 4 pipeline
            if (en_compare_stage3)
                match_precompute_stage4 <= match_comb_stage3;
            en_compare_stage4 <= en_compare_stage3;
            
            // Output stage
            if (en_compare_stage4)
                match <= match_precompute_stage4;
        end
    end
endmodule