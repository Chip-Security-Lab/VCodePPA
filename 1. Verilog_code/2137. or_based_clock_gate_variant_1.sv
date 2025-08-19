//SystemVerilog
//IEEE 1364-2005 Verilog
///////////////////////////////////////////
// Filename: or_based_clock_gate_top.v
// Top module for OR-based clock gating
// Enhanced pipeline structure with clear data flow
///////////////////////////////////////////

module or_based_clock_gate (
    input  wire clk_in,      // Input clock signal
    input  wire disable_n,   // Active-low disable signal
    output wire clk_out      // Gated clock output
);
    // Internal signals for improved data flow organization
    wire enable_signal;      // Inverted disable signal
    reg  pipeline_stage1;    // First pipeline register
    
    // Stage 1: Signal preparation path
    assign enable_signal = ~disable_n;
    
    // Stage 2: First pipeline register to break timing path
    always @(posedge clk_in or negedge disable_n) begin
        if (~disable_n)
            pipeline_stage1 <= 1'b1;
        else
            pipeline_stage1 <= enable_signal;
    end
    
    // Stage 3: Clock gating output logic
    // Using optimized datapath with registered enable for improved timing
    assign clk_out = clk_in | pipeline_stage1;
    
endmodule