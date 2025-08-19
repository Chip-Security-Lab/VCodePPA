//SystemVerilog
// Top-level module: IVMU_CDC_sync
// Refactored version decomposing the vector synchronizer
// into multiple single-bit synchronizer instances.
// Implements a multi-bit CDC synchronizer using standard two-flop stages
// for each bit of the input vector.
module IVMU_CDC_sync #(parameter WIDTH=4) (
    input src_clk,       // Source clock (not used in synchronizer logic)
    input dst_clk,       // Destination clock
    input [WIDTH-1:0] async_irq, // Asynchronous input vector
    output [WIDTH-1:0] sync_irq   // Synchronized output vector
);

// Instantiate WIDTH single-bit synchronizers
generate
    genvar i;
    for (i = 0; i < WIDTH; i = i + 1) begin : bit_sync_inst
        single_bit_cdc_sync u_single_bit_sync (
            .dst_clk  (dst_clk),
            .async_in (async_irq[i]),
            .sync_out (sync_irq[i]) // Connect sub-module output register to top-level output wire
        );
    end
endgenerate

endmodule // IVMU_CDC_sync

// Sub-module: single_bit_cdc_sync
// Implements a standard two-flop synchronizer for a single bit
// to safely cross from an asynchronous clock domain to the destination clock domain.
module single_bit_cdc_sync (
    input dst_clk,    // Destination clock
    input async_in,   // Asynchronous input bit
    output reg sync_out // Synchronized output bit (registered)
);

reg sync_reg1; // First stage register

always @(posedge dst_clk) begin
    sync_reg1 <= async_in;   // Sample asynchronous input
    sync_out  <= sync_reg1; // Sample first stage output (second stage register)
end

endmodule // single_bit_cdc_sync