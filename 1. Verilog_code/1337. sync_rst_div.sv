module sync_rst_div #(parameter DIV=8) (
    input clk, async_rst,
    output reg clk_out
);
reg [2:0] sync_rst_reg;
reg [3:0] cnt;

always @(posedge clk, posedge async_rst) begin
    if(async_rst) sync_rst_reg <= 3'b111;
    else sync_rst_reg <= {sync_rst_reg[1:0], 1'b0};
end

always @(posedge clk) begin
    if(sync_rst_reg[2]) {cnt,clk_out} <= 0;
    else if(cnt == DIV/2-1) begin
        cnt <= 0;
        clk_out <= ~clk_out;
    end else cnt <= cnt + 1;
end
endmodule
