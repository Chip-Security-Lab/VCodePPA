//SystemVerilog
module PhaseAligner #(parameter PHASE_STEPS=8) (
    input clk_ref, clk_data,
    output reg [7:0] aligned_data
);
    // Forward retimed design
    reg [7:0] sample_buffer [0:PHASE_STEPS-1];
    wire clk_ref_sampled;
    reg clk_ref_delayed;
    
    // Phase detection logic
    reg [7:0] phase_detect;
    
    // Move the input sampling register forward
    // by directly using clk_ref in the first stage
    assign clk_ref_sampled = clk_ref;
    
    // First stage: Delay the sampled clock reference
    always @(posedge clk_data) begin
        clk_ref_delayed <= clk_ref_sampled;
    end
    
    // Second stage: Handle the shift register first position
    always @(posedge clk_data) begin
        sample_buffer[0] <= clk_ref_delayed;
    end
    
    // Third stage: Handle the rest of the shift register positions
    // Split into multiple always blocks for better readability and synthesis
    genvar j;
    generate
        for (j = 1; j < PHASE_STEPS; j = j + 1) begin : shift_reg_gen
            always @(posedge clk_data) begin
                sample_buffer[j] <= sample_buffer[j-1];
            end
        end
    endgenerate
    
    // Fourth stage: Phase detection logic
    always @(posedge clk_data) begin
        phase_detect <= sample_buffer[0] ^ sample_buffer[PHASE_STEPS-1];
    end
    
    // Fifth stage: Output alignment logic
    always @(posedge clk_data) begin
        if (|phase_detect) begin
            aligned_data <= sample_buffer[PHASE_STEPS/2];
        end
    end
endmodule