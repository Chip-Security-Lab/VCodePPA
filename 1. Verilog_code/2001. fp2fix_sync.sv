module fp2fix_sync #(parameter Q=8)(input clk, rst, input [31:0] fp, output reg [30:0] fixed);
wire sign = fp[31];
wire [7:0] exp = fp[30:23]-127;
wire [22:0] mant = {1'b1, fp[22:0]};
always @(posedge clk) if(rst) fixed <= 0; else fixed <= sign ? -mant<<(exp-Q) : mant<<(exp-Q);
endmodule