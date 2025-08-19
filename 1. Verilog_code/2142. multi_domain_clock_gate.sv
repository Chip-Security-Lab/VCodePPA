module multi_domain_clock_gate (
    input  wire clk_a,
    input  wire clk_b,
    input  wire en_a,
    input  wire en_b,
    output wire gated_clk_a,
    output wire gated_clk_b
);
    assign gated_clk_a = clk_a & en_a;
    assign gated_clk_b = clk_b & ~en_b; // Inverted polarity
endmodule