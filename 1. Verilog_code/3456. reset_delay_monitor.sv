module reset_delay_monitor (
  input wire clk,
  input wire reset_n,
  output reg reset_stuck_error
);
  reg [15:0] delay_counter;

  always @(posedge clk) begin
    if (!reset_n)
      delay_counter <= delay_counter + 1;
    else
      delay_counter <= 0;

    if (delay_counter == 16'hFFFF)
      reset_stuck_error <= 1;
  end
endmodule
