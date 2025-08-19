module selective_bit_reset(
  input clk, rst_n,
  input reset_bit0, reset_bit1, reset_bit2,
  input [2:0] data_in,
  output reg [2:0] data_out
);
  always @(posedge clk) begin
    if (!rst_n)
      data_out <= 3'b000;
    else begin
      data_out[0] <= reset_bit0 ? 1'b0 : data_in[0];
      data_out[1] <= reset_bit1 ? 1'b0 : data_in[1];
      data_out[2] <= reset_bit2 ? 1'b0 : data_in[2];
    end
  end
endmodule
