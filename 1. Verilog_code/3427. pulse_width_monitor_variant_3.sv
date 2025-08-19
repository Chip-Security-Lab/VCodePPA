//SystemVerilog
module pulse_width_monitor #(
  parameter MIN_WIDTH = 4
) (
  input wire clk,
  input wire reset_in,
  output reg reset_valid
);
  reg [$clog2(MIN_WIDTH)-1:0] width_counter;
  reg reset_in_d;
  reg counter_max;
  reg reset_in_reg;
  wire reset_edge;
  
  // Detect reset edge and register input (moved forward)
  always @(posedge clk) begin
    reset_in_d <= reset_in;
    reset_in_reg <= reset_in;
  end
  
  // Extract combinational logic
  assign reset_edge = reset_in && !reset_in_d;
  
  // Counter logic
  always @(posedge clk) begin
    if (reset_edge)
      width_counter <= 0;
    else if (reset_in)
      width_counter <= width_counter + 1;
  end
  
  // Pre-compute counter_max and move to register before output logic
  always @(posedge clk) begin
    counter_max <= (width_counter >= MIN_WIDTH-1);
  end
  
  // Output register (now using pre-computed registered values)
  always @(posedge clk) begin
    reset_valid <= counter_max && reset_in_reg;
  end
endmodule