module WeightedArbiter #(parameter W=8) (
    input clk,
    input [3:0] req,
    input [31:0] weights,  // 扁平化: 4 x 8-bit weights
    output reg [3:0] grant
);
reg [W-1:0] cnt [0:3];
integer i;
always @(posedge clk) begin
    for(i=0; i<4; i=i+1) begin
        cnt[i] <= (grant[i]) ? cnt[i] - 1 : weights[i*8 +: 8];
        grant[i] <= (cnt[i] > 0) && req[i];
    end
end
endmodule