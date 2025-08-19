module char_gen (
    input clk, 
    input [9:0] h_cnt, v_cnt,
    output reg pixel, blank
);
parameter CHAR_WIDTH = 8;
always @(posedge clk) begin
    blank <= (h_cnt > 640) || (v_cnt > 480);
    pixel <= (h_cnt[2:0] < CHAR_WIDTH) ? 1'b1 : 1'b0;
end
endmodule
