module dual_cnt_div #(parameter DIV1=3, DIV2=5) (
    input clk, sel,
    output reg clk_out
);
reg [3:0] cnt1, cnt2;
always @(posedge clk) begin
    cnt1 <= (cnt1 == DIV1-1) ? 0 : cnt1 + 1;
    cnt2 <= (cnt2 == DIV2-1) ? 0 : cnt2 + 1;
    clk_out <= sel ? (cnt2 == 0) : (cnt1 == 0);
end
endmodule
