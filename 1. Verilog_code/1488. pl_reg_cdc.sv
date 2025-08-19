module pl_reg_cdc #(parameter W=8) (
    input src_clk, dst_clk,
    input [W-1:0] src_data,
    output reg [W-1:0] dst_data
);
reg [W-1:0] sync_reg;
always @(posedge src_clk) sync_reg <= src_data;
always @(posedge dst_clk) dst_data <= sync_reg;
endmodule