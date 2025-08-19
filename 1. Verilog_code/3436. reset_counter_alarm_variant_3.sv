//SystemVerilog
module reset_counter_alarm #(
  parameter ALARM_THRESHOLD = 4
) (
  input wire clk,
  input wire reset_in,
  input wire clear_counter,
  output reg alarm,
  output reg [3:0] reset_count
);
  // Internal signals
  reg reset_in_reg;
  reg reset_prev;
  reg clear_counter_reg;
  reg [3:0] count_internal;
  
  // Register inputs to improve timing
  always @(posedge clk) begin
    reset_in_reg <= reset_in;
    clear_counter_reg <= clear_counter;
  end
  
  // Edge detection - moved before combinational logic
  always @(posedge clk) begin
    reset_prev <= reset_in_reg;
  end
  
  // Counter update logic - simplified and retimed
  always @(posedge clk) begin
    if (clear_counter_reg) begin
      count_internal <= 4'd0;
    end
    else if (reset_in_reg && !reset_prev && count_internal < 4'hF) begin
      count_internal <= count_internal + 4'd1;
    end
  end
  
  // Output register stage - separated from computation
  always @(posedge clk) begin
    reset_count <= count_internal;
    alarm <= (count_internal >= ALARM_THRESHOLD);
  end
  
endmodule