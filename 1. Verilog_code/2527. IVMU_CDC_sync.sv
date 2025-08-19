module IVMU_CDC_sync #(parameter WIDTH=4) (
    input src_clk, dst_clk,
    input [WIDTH-1:0] async_irq,
    output reg [WIDTH-1:0] sync_irq
);
reg [WIDTH-1:0] meta;
always @(posedge src_clk) meta <= async_irq;
always @(posedge dst_clk) sync_irq <= meta;
endmodule
