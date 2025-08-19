//SystemVerilog
module data_scrambler #(
    parameter POLY_WIDTH = 16,
    parameter POLYNOMIAL = 16'hA001 // x^16 + x^12 + x^5 + 1
) (
    input wire clk, rst_n,
    input wire data_in,
    input wire scrambled_in,
    input wire bypass_scrambler,
    output reg scrambled_out,
    output reg data_out
);
    // Pre-calculate polynomial masks to reduce logic depth
    localparam [POLY_WIDTH-1:0] POLY_MASK = POLYNOMIAL & {POLY_WIDTH{1'b1}};
    
    // Split LFSR for better path balancing
    reg [POLY_WIDTH-1:0] lfsr_state;
    
    // Pipeline stage registers
    reg [POLY_WIDTH-1:0] lfsr_state_stage1;
    reg [POLY_WIDTH-1:0] lfsr_state_stage2;
    reg data_in_stage1, data_in_stage2;
    reg scrambled_in_stage1, scrambled_in_stage2;
    reg bypass_scrambler_stage1, bypass_scrambler_stage2;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Feedback registers for pipeline stages
    reg feedback_stage1, feedback_stage2;
    wire feedback;
    wire [3:0] partial_feedback;
    
    // Break up the large XOR tree into smaller balanced sections
    wire [3:0] section0_mask = POLY_MASK[3:0];
    wire [3:0] section1_mask = POLY_MASK[7:4];
    wire [3:0] section2_mask = POLY_MASK[11:8];
    wire [3:0] section3_mask = POLY_MASK[POLY_WIDTH-1:12];
    
    // Stage 1 signals
    wire [3:0] section0_lfsr = lfsr_state[3:0];
    wire [3:0] section1_lfsr = lfsr_state[7:4];
    wire [3:0] section2_lfsr = lfsr_state[11:8];
    wire [3:0] section3_lfsr = lfsr_state[POLY_WIDTH-1:12];
    
    // Compute complemented values (one's complement)
    wire [3:0] comp_mask0 = ~section0_mask;
    wire [3:0] comp_mask1 = ~section1_mask;
    wire [3:0] comp_mask2 = ~section2_mask;
    wire [3:0] comp_mask3 = ~section3_mask;
    
    // Use two's complement addition to compute AND operations
    // (A & B) ≡ ^(A + (~B + 1)) when reduced to a single bit result
    wire [4:0] sum0 = section0_lfsr + comp_mask0 + 4'b0001;
    wire [4:0] sum1 = section1_lfsr + comp_mask1 + 4'b0001;
    wire [4:0] sum2 = section2_lfsr + comp_mask2 + 4'b0001;
    wire [4:0] sum3 = section3_lfsr + comp_mask3 + 4'b0001;
    
    // Extract parity information from the sums
    assign partial_feedback[0] = ^sum0[3:0];
    assign partial_feedback[1] = ^sum1[3:0];
    assign partial_feedback[2] = ^sum2[3:0];
    assign partial_feedback[3] = ^sum3[3:0];
    
    // Combine partial feedbacks in a balanced tree structure
    assign feedback = partial_feedback[0] ^ partial_feedback[1] ^ 
                     partial_feedback[2] ^ partial_feedback[3];
    
    // Pre-compute next LFSR state
    wire [POLY_WIDTH-1:0] next_lfsr = {lfsr_state[POLY_WIDTH-2:0], feedback};
    
    // Stage 1: Compute feedback and next LFSR state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_state_stage1 <= {POLY_WIDTH{1'b1}};
            data_in_stage1 <= 1'b0;
            scrambled_in_stage1 <= 1'b0;
            bypass_scrambler_stage1 <= 1'b0;
            feedback_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            lfsr_state_stage1 <= next_lfsr;
            data_in_stage1 <= data_in;
            scrambled_in_stage1 <= scrambled_in;
            bypass_scrambler_stage1 <= bypass_scrambler;
            feedback_stage1 <= feedback;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Scramble data
    wire scrambled_data_stage2 = data_in_stage1 ^ feedback_stage1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_state_stage2 <= {POLY_WIDTH{1'b1}};
            data_in_stage2 <= 1'b0;
            scrambled_in_stage2 <= 1'b0;
            bypass_scrambler_stage2 <= 1'b0;
            feedback_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            lfsr_state_stage2 <= lfsr_state_stage1;
            data_in_stage2 <= data_in_stage1;
            scrambled_in_stage2 <= scrambled_in_stage1;
            bypass_scrambler_stage2 <= bypass_scrambler_stage1;
            feedback_stage2 <= feedback_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Output data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scrambled_out <= 1'b0;
            data_out <= 1'b0;
            valid_stage3 <= 1'b0;
            lfsr_state <= {POLY_WIDTH{1'b1}}; // Initialize to all 1s
        end else if (valid_stage2) begin
            // Update LFSR state for next input data
            lfsr_state <= lfsr_state_stage2;
            
            // Handle scrambler output with bypass option
            if (!bypass_scrambler_stage2) begin
                scrambled_out <= scrambled_data_stage2;
            end else begin
                scrambled_out <= data_in_stage2; // Bypass mode
            end
            
            // Descrambler operation
            data_out <= scrambled_in_stage2 ^ feedback_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
endmodule