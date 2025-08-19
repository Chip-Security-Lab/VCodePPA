module or_based_clock_gate (
    input  wire clk_in,
    input  wire disable_n,
    output wire clk_out
);
    // OR-based implementation with active-low disable
    assign clk_out = clk_in | ~disable_n;
endmodule