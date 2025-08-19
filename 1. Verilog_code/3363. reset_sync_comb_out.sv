module reset_sync_comb_out(
  input  wire clk,
  input  wire rst_in,
  output wire rst_out
);
  reg flop_a, flop_b;
  always @(posedge clk or negedge rst_in) begin
    if(!rst_in) begin
      flop_a <= 1'b0;
      flop_b <= 1'b0;
    end else begin
      flop_a <= 1'b1;
      flop_b <= flop_a;
    end
  end
  assign rst_out = flop_b & flop_a;
endmodule
