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
  reg reset_prev;
  reg [3:0] reset_count_int;
  reg [3:0] reset_count_buf;
  wire reset_edge_detected;
  wire threshold_reached;
  
  // Detect positive edge of reset_in
  assign reset_edge_detected = reset_in && !reset_prev;
  
  // Optimized threshold comparison
  assign threshold_reached = reset_count_int >= ALARM_THRESHOLD;
  
  always @(posedge clk) begin
    reset_prev <= reset_in;
    
    // Counter logic with priority to clear
    if (clear_counter)
      reset_count_int <= 4'd0;
    else if (reset_edge_detected && reset_count_int < 4'hF)
      reset_count_int <= reset_count_int + 4'd1;
    
    // Single buffer to reduce register usage while maintaining timing
    reset_count_buf <= reset_count_int;
    reset_count <= reset_count_buf;
    
    // Direct assignment of threshold comparison result
    alarm <= threshold_reached;
  end
endmodule