module RD2(
  input clk, input rst_n, input en,
  input [7:0] data_in,
  output [7:0] data_out
);
reg [7:0] r_reg;
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) r_reg <= 8'd0;
  else if (en) r_reg <= data_in;
end
assign data_out = r_reg;
endmodule
