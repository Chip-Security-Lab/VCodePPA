//SystemVerilog
module lfsr_div #(
    parameter POLY = 8'hB4
)(
    input  wire       clk,      // System clock input
    input  wire       rst,      // Active high reset
    output reg        clk_out   // Divided clock output
);

    // Pipeline stage registers for improved timing
    reg  [7:0] lfsr_stage1;     // First pipeline stage
    reg  [7:0] lfsr_stage2;     // Second pipeline stage  
    reg  [7:0] lfsr_stage3;     // Third pipeline stage
    reg  [7:0] lfsr_next;       // Next LFSR state
    
    // Feedback and intermediate signals
    wire       feedback_stage1;  // Feedback bit for LFSR stage 1
    reg        feedback_stage2;  // Pipelined feedback bit
    wire [7:0] shift_result;     // Intermediate shift result
    wire [7:0] xor_result;       // Intermediate XOR result
    
    // Zero detection pipeline registers
    reg        zero_detect_stage1;
    reg        zero_detect_stage2;
    reg        zero_detect_stage3;
    
    // Feedback calculation - separate from main datapath
    assign feedback_stage1 = lfsr_stage1[7];
    
    // Split combinational logic for better timing
    assign shift_result = {lfsr_stage1[6:0], 1'b0};
    assign xor_result = feedback_stage2 ? POLY : 8'h00;
    
    // LFSR Next State Logic - broken into stages
    always @(*) begin
        lfsr_next = shift_result ^ xor_result;
    end
    
    // Sequential logic - expanded pipeline stages
    always @(posedge clk) begin
        if (rst) begin
            // Reset values for all registers
            lfsr_stage1 <= 8'hFF;
            lfsr_stage2 <= 8'hFF;
            lfsr_stage3 <= 8'hFF;
            feedback_stage2 <= 1'b1;
            zero_detect_stage1 <= 1'b0;
            zero_detect_stage2 <= 1'b0;
            zero_detect_stage3 <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            // Pipeline stage 1: Capture feedback
            feedback_stage2 <= feedback_stage1;
            
            // Pipeline stage 2: Update LFSR state
            lfsr_stage2 <= lfsr_stage1;
            lfsr_stage3 <= lfsr_stage2;
            lfsr_stage1 <= lfsr_next;
            
            // Pipeline stages for zero detection
            zero_detect_stage1 <= (lfsr_next == 8'h00);
            zero_detect_stage2 <= zero_detect_stage1;
            zero_detect_stage3 <= zero_detect_stage2;
            
            // Final stage: Clock output generation
            clk_out <= zero_detect_stage3;
        end
    end

endmodule