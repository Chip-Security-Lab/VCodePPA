//SystemVerilog
//==============================================================================
//==============================================================================
module dual_clock_gate (
    input  wire fast_clk,   // High frequency clock input
    input  wire slow_clk,   // Low frequency clock input
    input  wire sel,        // Clock selection control signal
    output wire gated_clk   // Output gated clock
);

    // Clock selection register
    reg sel_reg;
    
    // Register the selection signal to improve timing and reduce glitches
    always @(posedge fast_clk) begin
        sel_reg <= sel;
    end
    
    // Optimized clock muxing using direct conditional operator
    // This eliminates the intermediate signals and simplifies the logic path
    assign gated_clk = sel_reg ? slow_clk : fast_clk;

endmodule