//SystemVerilog
module or_based_clock_gate (
    input  wire clk_in,     // Input clock signal
    input  wire disable_n,  // Active-low disable control signal
    output wire clk_out     // Gated clock output
);
    // Internal signal for glitch-free control
    reg  enable_latch;
    
    // Use active-high enable signal with latch to prevent glitches
    always @(clk_in or disable_n) begin
        if (!clk_in) // Latch when clock is low
            enable_latch <= disable_n;
    end
    
    // Use AND gate instead of OR gate with inverted logic
    // This improves power efficiency and is the standard clock gating approach
    assign clk_out = clk_in & enable_latch;
    
endmodule