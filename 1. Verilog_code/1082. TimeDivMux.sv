module TimeDivMux #(parameter DW=8) (
    input clk, rst,
    input [3:0][DW-1:0] ch,
    output reg [DW-1:0] out
);
reg [1:0] cnt;
always @(posedge clk)
    if(rst) cnt <= 0;
    else cnt <= cnt + 1;
always @* out = ch[cnt];
endmodule