module gray_div #(parameter WIDTH=4) (
    input clk, rst,
    output reg clk_div
);
reg [WIDTH-1:0] gray_cnt;
wire [WIDTH-1:0] bin_cnt = gray_cnt ^ (gray_cnt >> 1);

always @(posedge clk) begin
    if(rst) {gray_cnt,clk_div} <= 0;
    else begin
        gray_cnt <= gray_cnt + 1;
        clk_div <= (bin_cnt == {WIDTH{1'b1}});
    end
end
endmodule
