module MuxGatedClock #(parameter W=4) (
    input gclk, en,
    input [3:0][W-1:0] din,
    input [1:0] sel,
    output reg [W-1:0] q
);
wire clk_en = gclk & en;
always @(posedge clk_en) 
    q <= din[sel];
endmodule