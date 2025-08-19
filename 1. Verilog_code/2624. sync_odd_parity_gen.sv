module sync_odd_parity_gen(
  input clock, resetn,
  input [7:0] din,
  output reg p_out
);
  always @(posedge clock) begin
    if (!resetn)
      p_out <= 1'b0;
    else
      p_out <= ~(^din);
  end
endmodule