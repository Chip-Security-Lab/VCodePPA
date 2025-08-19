module vmem_ctrl #(parameter AW=12)(
    input clk, 
    output reg [AW-1:0] addr,
    output reg ref_en
);
reg [15:0] refresh_cnt;
always @(posedge clk) begin
    refresh_cnt <= refresh_cnt + 1;
    ref_en <= (refresh_cnt[15:13] == 3'b111);
    addr <= ref_en ? refresh_cnt[12:0] : addr;
end
endmodule
