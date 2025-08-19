//SystemVerilog
module cdc_buffer #(
    parameter DW = 8   // Data width parameter
) (
    input  wire          src_clk,    // Source clock domain
    input  wire          dst_clk,    // Destination clock domain
    input  wire [DW-1:0] din,        // Input data from source domain
    output reg  [DW-1:0] dout        // Output data to destination domain
);

    // Source domain registers
    reg [DW-1:0] src_data_reg;

    // Destination domain synchronization registers
    reg [DW-1:0] dst_sync_stage1;
    reg [DW-1:0] dst_sync_stage2;

    // Source domain data capture
    always @(posedge src_clk) begin
        src_data_reg <= din;
    end

    // Destination domain synchronization pipeline
    // Two-stage synchronizer to prevent metastability
    always @(posedge dst_clk) begin
        dst_sync_stage1 <= src_data_reg;   // First synchronization stage
        dst_sync_stage2 <= dst_sync_stage1; // Second synchronization stage
        dout <= dst_sync_stage2;           // Output register stage
    end

endmodule