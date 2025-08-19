//SystemVerilog
//===================================================================
// Module: clk_gate_dff
// Purpose: Clock-gated D flip-flop with improved data path structure
//===================================================================
module clk_gate_dff (
    input  wire clk,     // Main clock input
    input  wire en,      // Clock enable signal
    input  wire d,       // Data input
    output reg  q        // Data output
);

    // Internal signals for clock gating path
    wire   enable_latch;
    wire   gated_clk;
    
    // Clock gating logic with latch to prevent glitches
    // Use active-high transparent latch for enable signal
    reg    enable_latch_reg;
    
    always @(clk or en) begin
        if (!clk) begin
            enable_latch_reg <= en;
        end
    end
    
    assign enable_latch = enable_latch_reg;
    
    // Generate glitch-free gated clock
    assign gated_clk = clk & enable_latch;
    
    // Data path with properly gated clock
    always @(posedge gated_clk or posedge en) begin
        if (en)
            q <= d;
    end

endmodule