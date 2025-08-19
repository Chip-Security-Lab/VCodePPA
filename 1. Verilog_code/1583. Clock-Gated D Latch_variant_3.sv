//SystemVerilog
module d_latch_clock_gated (
    input wire d,
    input wire clk,
    input wire gate_en,
    output reg q
);
    wire gated_clk;
    assign gated_clk = clk & gate_en;
    
    always @(d, gated_clk) begin
        if (gated_clk)
            q = d;
    end
endmodule