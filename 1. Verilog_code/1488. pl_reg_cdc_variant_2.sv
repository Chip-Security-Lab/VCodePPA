//SystemVerilog
module pl_reg_cdc #(parameter W=8) (
    input src_clk, dst_clk,
    input [W-1:0] src_data,
    output reg [W-1:0] dst_data
);

// Synchronization register at source clock domain
reg [W-1:0] sync_reg1;
// Second stage synchronization register at destination clock domain
reg [W-1:0] sync_reg2;

// Source domain registration
always @(posedge src_clk) begin
    sync_reg1 <= src_data;
end

// Multi-stage synchronization at destination clock domain
// This implements backward register retiming by adding a second register
// in the destination domain for better metastability resolution
always @(posedge dst_clk) begin
    sync_reg2 <= sync_reg1;
    dst_data <= sync_reg2;
end

endmodule