module cdc_sync #(parameter WIDTH=1) (
    input src_clk, dst_clk, rst,
    input [WIDTH-1:0] async_in,
    output reg [WIDTH-1:0] sync_out
);
reg [WIDTH-1:0] sync_reg0, sync_reg1;

always @(posedge src_clk or posedge rst) 
    if (rst) sync_reg0 <= 0;
    else sync_reg0 <= async_in;

always @(posedge dst_clk or posedge rst) begin
    if (rst) {sync_reg1, sync_out} <= 0;
    else {sync_reg1, sync_out} <= {sync_reg0, sync_reg1};
end
endmodule