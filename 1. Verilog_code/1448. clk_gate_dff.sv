module clk_gate_dff (
    input clk, en,
    input d,
    output reg q
);
wire gated_clk = clk & en;
always @(posedge gated_clk)
    q <= d;
endmodule