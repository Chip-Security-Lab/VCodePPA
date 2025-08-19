//SystemVerilog
module sync_odd_parity_gen(
  input clock, resetn,
  input [7:0] din,
  output reg p_out
);
  wire [7:0] din_inv;

  // Invert the input data for parity calculation
  assign din_inv = ~din;

  always @(posedge clock or negedge resetn) begin
    if (!resetn)
      p_out <= 1'b0;
    else
      p_out <= |din_inv; // Use OR reduction for odd parity
  end
endmodule