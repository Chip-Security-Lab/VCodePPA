//SystemVerilog
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
    
    case ({reset_in_sync != reset_in, counter < DEBOUNCE_CYCLES-1})
      2'b10, 2'b11: // reset_in_sync != reset_in (优先级高)
        counter <= 0;
      2'b01: // counter < DEBOUNCE_CYCLES-1 且 reset_in_sync == reset_in
        counter <= counter + 1;
      2'b00: // counter >= DEBOUNCE_CYCLES-1 且 reset_in_sync == reset_in
        reset_out <= reset_in_sync;
    endcase
  end
endmodule