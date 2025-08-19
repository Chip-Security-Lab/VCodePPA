module delayed_reset_release #(
  parameter DELAY_CYCLES = 12
) (
  input wire clk,
  input wire reset_in,
  output reg reset_out
);
  reg [$clog2(DELAY_CYCLES):0] delay_counter;
  reg reset_falling;
  
  always @(posedge clk) begin
    reset_falling <= reset_in & ~reset_out;
    reset_out <= reset_in | (delay_counter != 0);
    
    if (reset_in)
      delay_counter <= DELAY_CYCLES;
    else if (delay_counter > 0)
      delay_counter <= delay_counter - 1;
  end
endmodule