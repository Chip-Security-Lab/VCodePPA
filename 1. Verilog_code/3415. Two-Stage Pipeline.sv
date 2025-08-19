module RD5 #(parameter W=8)(
  input clk, input rst, input en,
  input [W-1:0] din,
  output reg [W-1:0] dout
);
reg [W-1:0] stage1;
always @(posedge clk) begin
  if (rst) begin
    stage1 <= 0;
    dout   <= 0;
  end else if (en) begin
    stage1 <= din;
    dout   <= stage1;
  end
end
endmodule
