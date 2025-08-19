module RD10 #(parameter BITS=8)(
  input clk, input rst, input en,
  input [BITS-1:0] in_val,
  output reg [BITS-1:0] out_val
);
always @(posedge clk) begin
  if (rst)           out_val <= 0;
  else if (en)       out_val <= in_val;
  else               out_val <= 0;
end
endmodule
