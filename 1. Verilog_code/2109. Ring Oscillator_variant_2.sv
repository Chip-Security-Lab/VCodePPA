//SystemVerilog
module ring_oscillator #(
    parameter STAGES = 5,          // Number of inverter stages (must be odd)
    parameter DELAY_PS = 200       // Approximate stage delay in picoseconds
)(
    input wire enable,             // Oscillator enable control
    output wire clk_out            // Generated clock output
);
    // Main oscillation chain with optimized enable control
    wire [STAGES:0] osc_chain;     // Oscillation chain wires
    wire feedback_path;            // Feedback path from last to first stage
    reg enable_stage;              // Registered enable at optimized position
    
    // Push the enable register forward through the combinational logic
    // Enable is now sampled after some stages of the oscillator for better timing
    always @(posedge osc_chain[STAGES-1] or negedge enable) begin
        if (!enable)
            enable_stage <= 1'b0;
        else
            enable_stage <= enable;
    end
    
    // Feedback path with enable gating moved closer to output
    assign feedback_path = enable_stage ? osc_chain[STAGES] : 1'b0;
    assign osc_chain[0] = feedback_path;
    
    // Generate the inverter chain with balanced stages
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : osc_stage
            // First half of stages - optimized timing path
            if (i < STAGES/2) begin : first_pipeline
                not #(DELAY_PS - 10) inv_first (osc_chain[i+1], osc_chain[i]);
            end
            // Second half of stages with modified delay for better distribution
            else begin : second_pipeline
                not #(DELAY_PS + 10) inv_second (osc_chain[i+1], osc_chain[i]);
            end
        end
    endgenerate
    
    // Output buffer to isolate oscillator from load
    wire internal_clk;
    assign internal_clk = osc_chain[STAGES];
    
    // Improved output buffer with enhanced glitch filtering
    buf #(DELAY_PS/3) output_buffer (clk_out, internal_clk);
    
endmodule