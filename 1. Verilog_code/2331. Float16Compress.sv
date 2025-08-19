module Float16Compress (
    input clk, en,
    input [31:0] ieee754,
    output reg [15:0] fp16
);
wire [15:0] temp = {ieee754[31], ieee754[30:23]-127+15, ieee754[22:13]};
always @(posedge clk) if(en) 
    fp16 <= (ieee754[30:23] == 0) ? 0 : temp;
endmodule
