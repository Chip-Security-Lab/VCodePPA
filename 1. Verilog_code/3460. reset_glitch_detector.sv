module reset_glitch_detector (
  input wire clk,
  input wire reset_n,
  output reg glitch_detected
);
  reg reset_prev;

  always @(posedge clk) begin
    if (reset_n != reset_prev)
      glitch_detected <= 1;
    reset_prev <= reset_n;
  end
endmodule
