//SystemVerilog
//IEEE 1364-2005 Verilog
module PhaseAligner #(parameter PHASE_STEPS=8) (
    input clk_ref, clk_data,
    output reg [7:0] aligned_data
);
    // Pipeline registers for clk_ref sampling
    reg clk_ref_sample_stage1;
    reg clk_ref_sample_stage2;
    
    // Sample buffer storage - moved before combinational logic
    reg [7:0] sample_buffer [0:PHASE_STEPS-1];
    
    // Phase detection pre-computation registers
    reg phase_change_detected_pre;
    reg [7:0] middle_sample_reg;
    
    integer i;

    // First stage: sample clock reference and shift buffer
    always @(posedge clk_data) begin
        clk_ref_sample_stage1 <= clk_ref;
        
        // Buffer shifting with retimed logic - converted to while loop
        i = PHASE_STEPS-1;
        while (i > 0) begin
            sample_buffer[i] <= sample_buffer[i-1];
            i = i - 1;
        end
        sample_buffer[0] <= clk_ref_sample_stage1;
        
        // Pre-compute phase change detection and store middle sample
        // This pulls the comparison logic before the phase_change_detected register
        phase_change_detected_pre <= (sample_buffer[1] != sample_buffer[PHASE_STEPS-1]);
        middle_sample_reg <= sample_buffer[PHASE_STEPS/2];
    end

    // Second stage: process the pre-computed results
    always @(posedge clk_data) begin
        // Apply the phase change detection result
        if (phase_change_detected_pre) begin
            aligned_data <= middle_sample_reg;
        end
    end
endmodule