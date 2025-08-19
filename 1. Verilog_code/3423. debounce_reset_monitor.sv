module debounce_reset_monitor #(
  parameter DEBOUNCE_CYCLES = 8
) (
  input wire clk,
  input wire reset_in,
  output reg reset_out
);
  reg [$clog2(DEBOUNCE_CYCLES)-1:0] counter;
  reg reset_in_sync;
  
  always @(posedge clk) begin
    reset_in_sync <= reset_in;
    if (reset_in_sync != reset_in)
      counter <= 0;
    else if (counter < DEBOUNCE_CYCLES-1)
      counter <= counter + 1;
    else
      reset_out <= reset_in_sync;
  end
endmodule