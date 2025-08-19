module MuxPipeline #(parameter W=16) (
    input clk,
    input [3:0][W-1:0] ch,
    input [1:0] sel,
    output reg [W-1:0] dout_reg
);
reg [W-1:0] stage;
always @(posedge clk) begin
    stage <= ch[sel];
    dout_reg <= stage;
end
endmodule