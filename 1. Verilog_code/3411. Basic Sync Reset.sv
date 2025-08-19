module RD1 #(parameter DW=8)(
  input clk, input rst,
  input [DW-1:0] din,
  output reg [DW-1:0] dout
);
always @(posedge clk) begin
  if (rst) dout <= 0;
  else     dout <= din;
end
endmodule
