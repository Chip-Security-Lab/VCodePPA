module reset_stretcher #(
  parameter STRETCH_CYCLES = 16
) (
  input wire clk,
  input wire reset_in,
  output reg reset_out
);
  reg [$clog2(STRETCH_CYCLES):0] counter;
  
  always @(posedge clk) begin
    if (reset_in)
      counter <= STRETCH_CYCLES;
    else if (counter > 0)
      counter <= counter - 1;
      
    reset_out <= (counter > 0) | reset_in;
  end
endmodule