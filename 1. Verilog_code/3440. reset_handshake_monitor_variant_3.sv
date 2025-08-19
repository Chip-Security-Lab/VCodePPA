//SystemVerilog
module reset_handshake_monitor (
  input wire clk,
  input wire reset_req,
  input wire reset_ack,
  output reg reset_active,
  output reg timeout_error
);
  // Enhanced timeout counter with optimized width
  reg [7:0] timeout_counter;
  
  // Optimized buffering scheme for critical signals
  reg reset_req_r1, reset_req_r2;
  reg reset_active_r1;
  reg reset_ack_r;
  
  // Signal buffering with reduced fanout
  always @(posedge clk) begin
    reset_req_r1 <= reset_req;
    reset_req_r2 <= reset_req_r1;
    reset_active_r1 <= reset_active;
    reset_ack_r <= reset_ack;
  end
  
  // FSM state signals with improved logic structure
  wire should_start_reset = reset_req_r2 && !reset_active;
  wire should_end_reset = reset_active_r1 && reset_ack_r;
  wire timeout_condition = reset_active && !reset_ack_r && (timeout_counter == 8'hFF);
  wire counter_active = reset_active && !reset_ack_r && (timeout_counter != 8'hFF);
  
  // Reset active control logic
  always @(posedge clk) begin
    if (should_start_reset)
      reset_active <= 1'b1;
    else if (should_end_reset)
      reset_active <= 1'b0;
  end
  
  // Timeout counter with range-based optimization
  always @(posedge clk) begin
    if (!reset_active || should_start_reset)
      timeout_counter <= 8'd0;
    else if (counter_active)
      timeout_counter <= timeout_counter + 8'd1;
  end
  
  // Timeout error logic with priority encoding
  always @(posedge clk) begin
    if (reset_req_r1 && !reset_active_r1)
      timeout_error <= 1'b0;
    else if (timeout_condition)
      timeout_error <= 1'b1;
  end
endmodule