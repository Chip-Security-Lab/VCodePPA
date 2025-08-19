//SystemVerilog

//-----------------------------------------------------------------------------
// Module: clk_pass_through
// Function: Passes the reference clock through when enable is high
//-----------------------------------------------------------------------------
module clk_pass_through (
    input  wire clk_in,     // Reference clock input
    input  wire enable,     // Clock enable
    output wire clk_out     // Clock output (gated)
);
    assign clk_out = enable ? clk_in : 1'b0;
endmodule

//-----------------------------------------------------------------------------
// Module: clk_gen_with_enable
// Top-level clock generator with enable control
//-----------------------------------------------------------------------------
module clk_gen_with_enable(
    input  wire i_ref_clk,   // Reference clock input
    input  wire i_rst,       // Active high reset
    input  wire i_enable,    // Module enable
    output wire o_clk        // Clock output
);

    // Internal signal for gated clock
    wire clk_gated;

    // Clock gating submodule instance
    clk_pass_through u_clk_pass_through (
        .clk_in   (i_ref_clk),
        .enable   (i_enable),
        .clk_out  (clk_gated)
    );

    // Output assignment (no reset applied as original code does not use it)
    assign o_clk = clk_gated;

endmodule