module sync_even_parity(
  input clk, rst,
  input [15:0] data,
  output reg parity
);
  always @(posedge clk) begin
    if (rst)
      parity <= 1'b0;
    else
      parity <= ^data;
  end
endmodule