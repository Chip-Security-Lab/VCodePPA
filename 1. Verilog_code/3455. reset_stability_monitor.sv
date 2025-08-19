module reset_stability_monitor (
  input wire clk,
  input wire reset_n,
  output reg reset_unstable
);
  reg reset_prev;
  reg [3:0] glitch_counter;

  always @(posedge clk) begin
    if (reset_n != reset_prev) begin
      glitch_counter <= glitch_counter + 1;
    end
    reset_prev <= reset_n;

    if (glitch_counter > 4'd5) begin
      reset_unstable <= 1;
    end
  end
endmodule
