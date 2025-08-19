//SystemVerilog
module data_scrambler #(
    parameter POLY_WIDTH = 16,
    parameter POLYNOMIAL = 16'hA001 // x^16 + x^12 + x^5 + 1
) (
    input wire clk, rst_n,
    input wire data_in,
    input wire scrambled_in,
    input wire bypass_scrambler,
    output wire scrambled_out,
    output wire data_out
);
    // Main LFSR registers
    reg [POLY_WIDTH-1:0] lfsr_state;
    
    // Input pipeline registers
    reg data_in_pipe, bypass_scrambler_pipe;
    
    // Break feedback computation into smaller chunks with register retiming
    wire [POLY_WIDTH/2-1:0] partial_feedback_high, partial_feedback_low;
    reg partial_feedback_high_reg, partial_feedback_low_reg;
    reg feedback;
    
    // Pre-computation registers for next state logic
    reg [POLY_WIDTH-2:0] lfsr_state_shifted;
    reg scrambled_out_reg;
    
    // First stage of feedback calculation - pushed before combinational logic
    assign partial_feedback_high = ^(lfsr_state[POLY_WIDTH-1:POLY_WIDTH/2] & POLYNOMIAL[POLY_WIDTH-1:POLY_WIDTH/2]);
    assign partial_feedback_low = ^(lfsr_state[POLY_WIDTH/2-1:0] & POLYNOMIAL[POLY_WIDTH/2-1:0]);
    
    // Pipeline the input data to align with feedback computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_pipe <= 1'b0;
            bypass_scrambler_pipe <= 1'b0;
            // Register the partial feedback results
            partial_feedback_high_reg <= 1'b0;
            partial_feedback_low_reg <= 1'b0;
        end else begin
            data_in_pipe <= data_in;
            bypass_scrambler_pipe <= bypass_scrambler;
            // Register the partial feedback results
            partial_feedback_high_reg <= partial_feedback_high;
            partial_feedback_low_reg <= partial_feedback_low;
        end
    end
    
    // Complete feedback computation in second stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            feedback <= 1'b0;
            lfsr_state_shifted <= {(POLY_WIDTH-1){1'b1}}; // Initialize to all 1s
            scrambled_out_reg <= 1'b0;
        end else begin
            // Second pipeline stage - complete feedback computation
            feedback <= partial_feedback_high_reg ^ partial_feedback_low_reg;
            // Pre-compute the next LFSR state except for the last bit
            lfsr_state_shifted <= lfsr_state[POLY_WIDTH-2:0];
            // Pre-compute scrambled output based on bypass mode
            scrambled_out_reg <= bypass_scrambler_pipe ? data_in_pipe : (data_in_pipe ^ feedback);
        end
    end
    
    // Final stage - update complete LFSR state with pre-computed values
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_state <= {POLY_WIDTH{1'b1}}; // Initialize to all 1s
        end else begin
            // Update LFSR state using pre-computed shifted state and feedback
            lfsr_state <= {lfsr_state_shifted, feedback};
        end
    end
    
    // Connect the pre-computed output to module output
    assign scrambled_out = scrambled_out_reg;
    
    // Descrambler output (placeholder for now)
    reg data_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) data_out_reg <= 1'b0;
        // Descrambler would be implemented here
    end
    
    assign data_out = data_out_reg;
endmodule