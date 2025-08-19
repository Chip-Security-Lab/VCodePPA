module dual_clock_gate (
    input  wire fast_clk,
    input  wire slow_clk,
    input  wire sel,
    output wire gated_clk
);
    wire fast_path, slow_path;
    
    assign fast_path = fast_clk & ~sel;
    assign slow_path = slow_clk & sel;
    assign gated_clk = fast_path | slow_path;
endmodule