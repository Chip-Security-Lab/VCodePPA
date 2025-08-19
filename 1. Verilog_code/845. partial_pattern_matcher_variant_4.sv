//SystemVerilog
// SystemVerilog
module partial_pattern_matcher #(
    parameter W = 16, 
    parameter SLICE = 8
)(
    input wire [W-1:0] data,
    input wire [W-1:0] pattern,
    input wire clk,                // Added clock for pipelining
    input wire rst_n,              // Added reset signal 
    input wire match_upper,        // Control to select which half to match
    output reg match_result        // Changed to register for pipelining
);
    // Stage 1: Data section extraction
    reg [SLICE-1:0] upper_data_section;
    reg [SLICE-1:0] upper_pattern_section;
    reg [SLICE-1:0] lower_data_section;
    reg [SLICE-1:0] lower_pattern_section;
    reg match_upper_r1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            upper_data_section <= {SLICE{1'b0}};
            upper_pattern_section <= {SLICE{1'b0}};
            lower_data_section <= {SLICE{1'b0}};
            lower_pattern_section <= {SLICE{1'b0}};
            match_upper_r1 <= 1'b0;
        end else begin
            upper_data_section <= data[W-1:W-SLICE];
            upper_pattern_section <= pattern[W-1:W-SLICE];
            lower_data_section <= data[SLICE-1:0];
            lower_pattern_section <= pattern[SLICE-1:0];
            match_upper_r1 <= match_upper;
        end
    end
    
    // Stage 2: Comparison using conditional inverse subtractor
    reg upper_match_result;
    reg lower_match_result;
    reg match_upper_r2;
    
    // Subtraction signals for upper section
    reg [SLICE-1:0] upper_xor_result;
    reg [SLICE:0] upper_borrow;
    reg upper_match_temp;
    
    // Subtraction signals for lower section
    reg [SLICE-1:0] lower_xor_result;
    reg [SLICE:0] lower_borrow;
    reg lower_match_temp;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            upper_match_result <= 1'b0;
            lower_match_result <= 1'b0;
            match_upper_r2 <= 1'b0;
            upper_xor_result <= {SLICE{1'b0}};
            upper_borrow <= {(SLICE+1){1'b0}};
            lower_xor_result <= {SLICE{1'b0}};
            lower_borrow <= {(SLICE+1){1'b0}};
            upper_match_temp <= 1'b0;
            lower_match_temp <= 1'b0;
        end else begin
            // Conditional inverse subtractor for upper comparison
            upper_xor_result <= upper_data_section ^ upper_pattern_section;
            upper_borrow[0] <= 1'b0;
            
            for (int i = 0; i < SLICE; i++) begin
                upper_borrow[i+1] <= (upper_data_section[i] & ~upper_pattern_section[i]) | 
                                    (upper_borrow[i] & (upper_data_section[i] | ~upper_pattern_section[i]));
            end
            
            upper_match_temp <= (upper_borrow[SLICE] == 1'b0) && (upper_xor_result == {SLICE{1'b0}});
            upper_match_result <= upper_match_temp;
            
            // Conditional inverse subtractor for lower comparison
            lower_xor_result <= lower_data_section ^ lower_pattern_section;
            lower_borrow[0] <= 1'b0;
            
            for (int i = 0; i < SLICE; i++) begin
                lower_borrow[i+1] <= (lower_data_section[i] & ~lower_pattern_section[i]) | 
                                    (lower_borrow[i] & (lower_data_section[i] | ~lower_pattern_section[i]));
            end
            
            lower_match_temp <= (lower_borrow[SLICE] == 1'b0) && (lower_xor_result == {SLICE{1'b0}});
            lower_match_result <= lower_match_temp;
            
            match_upper_r2 <= match_upper_r1;
        end
    end
    
    // Stage 3: Selection and output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_result <= 1'b0;
        end else begin
            match_result <= match_upper_r2 ? upper_match_result : lower_match_result;
        end
    end
    
endmodule