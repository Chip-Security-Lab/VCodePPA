module pulse_width_monitor #(
  parameter MIN_WIDTH = 4
) (
  input wire clk,
  input wire reset_in,
  output reg reset_valid
);
  reg [$clog2(MIN_WIDTH)-1:0] width_counter;
  reg reset_in_d;
  
  always @(posedge clk) begin
    reset_in_d <= reset_in;
    if (reset_in && !reset_in_d)
      width_counter <= 0;
    else if (reset_in)
      width_counter <= width_counter + 1;
    
    reset_valid <= (width_counter >= MIN_WIDTH-1) && reset_in;
  end
endmodule
