//SystemVerilog
// Top-level module: Hierarchical clock generator with enable and reset control
module clk_gen_with_enable (
    input  wire i_ref_clk,   // Reference clock input
    input  wire i_rst,       // Active high reset
    input  wire i_enable,    // Module enable
    output wire o_clk        // Clock output
);

    wire gated_clk;
    wire reset_controlled_clk;

    // Instance: Clock Gating Submodule
    clk_gen_gating_unit u_gating_unit (
        .clk_in(i_ref_clk),
        .clk_enable(i_enable),
        .clk_gated(gated_clk)
    );

    // Instance: Clock Reset Submodule
    clk_gen_reset_unit u_reset_unit (
        .clk_in(gated_clk),
        .reset_n(~i_rst),
        .clk_out(reset_controlled_clk)
    );

    assign o_clk = reset_controlled_clk;

endmodule

//------------------------------------------------------------------------------
// Submodule: clk_gen_gating_unit
// Function: Gate the input reference clock using enable signal
//------------------------------------------------------------------------------
module clk_gen_gating_unit (
    input  wire clk_in,           // Reference clock input
    input  wire clk_enable,       // Clock enable signal
    output wire clk_gated         // Gated clock output
);
    assign clk_gated = clk_enable ? clk_in : 1'b0;
endmodule

//------------------------------------------------------------------------------
// Submodule: clk_gen_reset_unit
// Function: Reset control for the gated clock output
//------------------------------------------------------------------------------
module clk_gen_reset_unit (
    input  wire clk_in,           // Gated clock input
    input  wire reset_n,          // Active low reset
    output wire clk_out           // Output clock with reset control
);
    assign clk_out = reset_n ? clk_in : 1'b0;
endmodule