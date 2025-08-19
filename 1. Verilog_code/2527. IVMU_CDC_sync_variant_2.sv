//SystemVerilog
module IVMU_CDC_sync #(parameter WIDTH=8) ( // Changed default width to 8
    input src_clk, dst_clk,
    input [WIDTH-1:0] async_irq,
    output reg [WIDTH-1:0] sync_irq
);
// Added an intermediate register for a 3-stage synchronizer
reg [WIDTH-1:0] meta_src;    // First stage, source clock domain
reg [WIDTH-1:0] meta_dst1;   // Second stage, destination clock domain

// First stage register in the source clock domain
always @(posedge src_clk) begin
    meta_src <= async_irq;
end

// Second stage register in the destination clock domain
// This register samples the signal crossing the clock boundary
always @(posedge dst_clk) begin
    meta_dst1 <= meta_src;
end

// Third stage register in the destination clock domain
// This register provides the synchronized output
always @(posedge dst_clk) begin
    sync_irq <= meta_dst1;
end

endmodule