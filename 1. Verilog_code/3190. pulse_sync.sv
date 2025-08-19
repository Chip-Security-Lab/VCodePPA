module pulse_sync #(
    parameter DST_CLK_RATIO = 2
)(
    input src_clk,
    input dst_clk,
    input src_pulse,
    output dst_pulse
);
reg [2:0] sync_chain;
reg src_flag, dst_flag;

always @(posedge src_clk) begin
    if (src_pulse) src_flag <= ~src_flag;
end

always @(posedge dst_clk) begin
    sync_chain <= {sync_chain[1:0], src_flag};
    dst_flag <= sync_chain[2];
end

assign dst_pulse = (sync_chain[2] ^ dst_flag);
endmodule
