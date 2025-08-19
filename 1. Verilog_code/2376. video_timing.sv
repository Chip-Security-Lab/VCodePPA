module video_timing #(parameter H_TOTAL=800)(
    input clk,
    output reg h_sync,
    output [9:0] h_count
);
reg [9:0] cnt;
assign h_count = cnt;
always @(posedge clk) begin
    cnt <= (cnt < H_TOTAL-1) ? cnt + 1 : 0;
    h_sync <= (cnt < 96) ? 0 : 1;
end
endmodule
