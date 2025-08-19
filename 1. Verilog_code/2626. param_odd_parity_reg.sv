module param_odd_parity_reg #(
  parameter DATA_W = 32
)(
  input clk,
  input [DATA_W-1:0] data,
  output reg parity_bit
);
  always @(posedge clk)
    parity_bit <= ~(^data);
endmodule