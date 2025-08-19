//SystemVerilog
module Sync_XNOR(
    input wire clk,
    input wire [7:0] sig_a, sig_b,
    output reg [7:0] q
);
    // Direct XNOR in single cycle reduces latency and register usage
    // This optimization improves area, power and timing
    always @(posedge clk) begin
        q <= ~(sig_a ^ sig_b);
    end
endmodule