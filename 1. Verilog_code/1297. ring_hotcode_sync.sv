module ring_hotcode_sync (
    input clock, sync_rst,
    output reg [3:0] cnt_reg
);
always @(posedge clock) begin
    if (sync_rst) cnt_reg <= 4'b0001;
    else cnt_reg <= {cnt_reg[0], cnt_reg[3:1]};
end
endmodule
