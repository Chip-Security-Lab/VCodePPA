//SystemVerilog
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
    
    if (reset_in == 1'b1) begin
      // reset_in is active (covers both 2'b10 and 2'b11 cases)
      delay_counter <= DELAY_CYCLES;
    end else if (|delay_counter) begin
      // reset_in is inactive but counter still counting (2'b01)
      delay_counter <= delay_counter - 1;
    end else begin
      // reset_in inactive and counter zero (2'b00)
      delay_counter <= delay_counter;
    end
  end
endmodule