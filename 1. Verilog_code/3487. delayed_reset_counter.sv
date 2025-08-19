module one_hot_encoder_reset(
  input clk, rst,
  input [2:0] binary_in,
  output reg [7:0] one_hot_out
);
  always @(posedge clk) begin
    if (rst)
      one_hot_out <= 8'h00;
    else
      one_hot_out <= (8'h01 << binary_in);
  end
endmodule