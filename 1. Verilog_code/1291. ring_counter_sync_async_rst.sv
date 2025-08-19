module ring_counter_sync_async_rst (
    input clk, rst_n,
    output reg [3:0] cnt
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) cnt <= 4'b0001;
    else cnt <= {cnt[0], cnt[3:1]};
end
endmodule
