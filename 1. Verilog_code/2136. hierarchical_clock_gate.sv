module hierarchical_clock_gate (
    input  wire master_clk,
    input  wire global_en,
    input  wire local_en,
    output wire block_clk
);
    wire primary_gated_clk;
    
    assign primary_gated_clk = master_clk & global_en;
    assign block_clk = primary_gated_clk & local_en;
endmodule