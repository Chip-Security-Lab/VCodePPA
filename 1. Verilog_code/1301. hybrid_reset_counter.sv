module hybrid_reset_counter (
    input clk, async_rst, sync_clear,
    output reg [3:0] data_out
);
always @(posedge clk or posedge async_rst) begin
    if (async_rst) data_out <= 4'b1000;
    else if (sync_clear) data_out <= 4'b0001;
    else data_out <= {data_out[0], data_out[3:1]};
end
endmodule
