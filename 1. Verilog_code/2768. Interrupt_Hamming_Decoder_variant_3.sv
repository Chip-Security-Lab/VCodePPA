//SystemVerilog
module Interrupt_Hamming_Decoder(
    input clk,
    input [7:0] code_in,
    output reg [3:0] data_out,
    output reg uncorrectable_irq
);
    // Stage 1 registers - Input capture and parity calculation
    reg [7:0] code_stage1;
    reg [2:0] syndrome_stage1;  // Combined parity syndrome
    
    // Stage 2 registers - Error detection and correction
    reg [7:0] code_stage2;
    reg [2:0] syndrome_stage2;
    reg [1:0] error_state_stage2;
    
    // Stage 3 registers - Data extraction and output preparation
    reg [3:0] data_stage3;
    reg [1:0] error_state_stage3;
    
    // Pipeline Stage 1: Capture input and calculate unified syndrome
    always @(posedge clk) begin
        // Capture input
        code_stage1 <= code_in;
        
        // Calculate syndrome bits in one operation
        syndrome_stage1[0] <= ^code_in;                             // Overall parity
        syndrome_stage1[1] <= code_in[7] ^ code_in[6] ^ code_in[5] ^ code_in[4] ^ code_in[0]; // Check1
        syndrome_stage1[2] <= code_in[7] ^ code_in[6] ^ code_in[3] ^ code_in[2] ^ code_in[1]; // Check2
    end
    
    // Pipeline Stage 2: Error detection based on syndrome pattern
    always @(posedge clk) begin
        // Pass data to next stage
        code_stage2 <= code_stage1;
        syndrome_stage2 <= syndrome_stage1;
        
        // Determine error state using optimized syndrome pattern matching
        casez (syndrome_stage1)
            3'b0??: error_state_stage2 <= 2'b00; // No errors - syndrome[0] is 0
            3'b101: error_state_stage2 <= 2'b01; // First type of single-bit error
            3'b110: error_state_stage2 <= 2'b10; // Second type of single-bit error
            3'b111: error_state_stage2 <= 2'b11; // Uncorrectable error - all syndrome bits set
            default: error_state_stage2 <= 2'b11; // Default to uncorrectable for other patterns
        endcase
    end
    
    // Pipeline Stage 3: Data extraction and output preparation
    always @(posedge clk) begin
        // Extract data bits directly
        data_stage3 <= code_stage2[7:4];
        error_state_stage3 <= error_state_stage2;
        
        // Final output stage with direct comparison
        data_out <= data_stage3;
        uncorrectable_irq <= error_state_stage3[0] & error_state_stage3[1]; // Optimized test for 2'b11
    end
endmodule