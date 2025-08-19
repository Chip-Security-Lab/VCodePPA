module IVMU_Timestamp #(parameter TS_W=16) (
    input clk,
    input [TS_W-1:0] ts [0:3],
    output reg [1:0] sel
);
always @(posedge clk) begin
    sel <= (ts[0] < ts[1]) ? 
          ((ts[0] < ts[2]) ? 0 : 2) : 
          ((ts[1] < ts[2]) ? 1 : 2);
end
endmodule
