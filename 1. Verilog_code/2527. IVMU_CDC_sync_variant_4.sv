//SystemVerilog
// SystemVerilog
module IVMU_CDC_sync_pipelined #(parameter WIDTH=4) (
    input src_clk, dst_clk,
    input src_rst_n, dst_rst_n,
    input [WIDTH-1:0] async_irq,
    output reg [WIDTH-1:0] sync_irq
);

// Stage 1: Register in src_clk domain (as per original code structure)
// Captures the asynchronous input in the source clock domain.
reg [WIDTH-1:0] data_stage1;
always @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
        data_stage1 <= {WIDTH{1'b0}};
    end else begin
        data_stage1 <= async_irq;
    end
end

// Stage 2: First synchronization register in dst_clk domain
// This register samples the data from the source domain register.
reg [WIDTH-1:0] data_stage2;
always @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
        data_stage2 <= {WIDTH{1'b0}};
    end else begin
        data_stage2 <= data_stage1; // Crosses clock domain here
    end
end

// Stage 3: Second synchronization register in dst_clk domain
// This register further synchronizes the data, reducing metastability risk.
reg [WIDTH-1:0] data_stage3;
always @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
        data_stage3 <= {WIDTH{1'b0}};
    end else begin
        data_stage3 <= data_stage2; // Synchronous transfer within dst_clk
    end
end

// Stage 4: Third synchronization register in dst_clk domain (final output)
// This register provides the final synchronized output.
always @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
        sync_irq <= {WIDTH{1'b0}};
    end else begin
        sync_irq <= data_stage3; // Synchronous transfer within dst_clk
    end
end

endmodule