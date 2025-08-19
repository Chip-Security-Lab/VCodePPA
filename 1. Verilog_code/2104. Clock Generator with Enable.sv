module clk_gen_with_enable(
    input i_ref_clk,   // Reference clock input
    input i_rst,       // Active high reset
    input i_enable,    // Module enable
    output o_clk       // Clock output
);
    assign o_clk = i_enable ? i_ref_clk : 1'b0;
endmodule