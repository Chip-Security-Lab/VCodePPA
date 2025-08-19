module BurstArbiter #(parameter BURST_LEN=4) (
    input clk, rst, en,
    input [3:0] req,
    output reg [3:0] grant
);
reg [1:0] burst_cnt;
always @(posedge clk) begin
    if(rst) {grant, burst_cnt} <= 0;
    else if(en) begin
        if(|grant) begin
            burst_cnt <= (burst_cnt == BURST_LEN-1) ? 0 : burst_cnt + 1;
            grant <= (burst_cnt == BURST_LEN-1) ? req & -req : grant;
        end else begin
            grant <= req & -req;
            burst_cnt <= 0;
        end
    end
end
endmodule
