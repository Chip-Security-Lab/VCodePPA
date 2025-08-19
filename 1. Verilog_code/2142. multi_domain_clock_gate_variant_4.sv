//SystemVerilog
module multi_domain_clock_gate (
    input  wire clk_a,
    input  wire clk_b,
    input  wire en_a,
    input  wire en_b,
    output wire gated_clk_a,
    output wire gated_clk_b
);
    // Optimized latch-based clock gating for improved PPA
    reg latch_en_a;
    reg latch_en_b;
    
    // Transparent latch for en_a (active high)
    // Using non-blocking assignment with explicit sensitivity to clk_a negative edge
    always @(clk_a or en_a) begin
        if (!clk_a)
            latch_en_a <= en_a;
    end
    
    // Transparent latch for en_b (active high with inverted output)
    // Using non-blocking assignment with explicit sensitivity to clk_b negative edge
    always @(clk_b or en_b) begin
        if (!clk_b)
            latch_en_b <= en_b;
    end
    
    // Optimized clock gating with latched enable signals
    assign gated_clk_a = clk_a & latch_en_a;
    assign gated_clk_b = clk_b & ~latch_en_b; // Inverting latch_en_b at the output instead of input
endmodule