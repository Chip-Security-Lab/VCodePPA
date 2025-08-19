module ArithEncoder #(PREC=8) (
    input clk, rst_n,
    input [7:0] data,
    output reg [PREC-1:0] code
);
reg [PREC-1:0] low=0, range=255;
always @(posedge clk) begin
    if(!rst_n) {low, range} <= 0;
    else begin
        range <= range / 256 * data;
        low <= low + (range - range*data/256);
        code <= low[PREC-1:0];
    end
end
endmodule
