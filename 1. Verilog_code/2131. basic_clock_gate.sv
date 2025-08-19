module basic_clock_gate (
    input  wire clk_in,
    input  wire enable,
    output wire clk_out
);
    // Basic AND gate implementation
    assign clk_out = clk_in & enable;
endmodule