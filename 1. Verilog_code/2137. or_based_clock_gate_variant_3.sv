//SystemVerilog
module or_based_clock_gate (
    input  wire clk_in,     // Input clock signal
    input  wire disable_n,  // Active-low disable control signal
    output wire clk_out     // Gated output clock
);
    // Internal signals for structured clock gating
    wire enable_signal;
    reg  latched_enable;
    
    // Enable logic path - prepare control signal
    assign enable_signal = disable_n;
    
    // Latch the enable signal on negative edge to prevent glitches
    always @(negedge clk_in or negedge disable_n) begin
        if (!disable_n)
            latched_enable <= 1'b0;
        else
            latched_enable <= enable_signal;
    end
    
    // Clock output data path - final gating logic
    // Using structured AND-based implementation for better timing and power
    assign clk_out = clk_in & latched_enable;
    
endmodule