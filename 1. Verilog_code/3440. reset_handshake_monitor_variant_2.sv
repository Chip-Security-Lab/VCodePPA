//SystemVerilog
//IEEE 1364-2005 Verilog
module reset_handshake_monitor (
  input  wire clk,
  input  wire reset_req,
  input  wire reset_ack,
  output reg  reset_active,
  output reg  timeout_error
);

  // ===== Stage 1: Request Detection =====
  reg        req_detected;
  reg        req_detected_r;
  
  // Request detection logic
  always @(posedge clk) begin
    req_detected <= reset_req && !reset_active;
  end
  
  // Request detection register
  always @(posedge clk) begin
    req_detected_r <= req_detected;
  end
  
  // ===== Stage 2: Timeout Management =====
  reg [7:0]  timeout_counter;
  reg        counter_at_max;
  reg        active_and_not_ack;
  
  // Active but not acknowledged state
  always @(posedge clk) begin
    active_and_not_ack <= reset_active && !reset_ack;
  end
  
  // Counter maximum detection
  always @(posedge clk) begin
    counter_at_max <= (timeout_counter == 8'hFF);
  end
  
  // Timeout counter logic
  always @(posedge clk) begin
    if (req_detected)
      timeout_counter <= 8'd0;
    else if (active_and_not_ack && !counter_at_max)
      timeout_counter <= timeout_counter + 8'd1;
  end
  
  // ===== Stage 3: Reset Control =====
  reg active_and_ack;
  
  // Active and acknowledged state
  always @(posedge clk) begin
    active_and_ack <= reset_active && reset_ack;
  end
  
  // Reset active state management
  always @(posedge clk) begin
    if (req_detected)
      reset_active <= 1'b1;
    else if (active_and_ack)
      reset_active <= 1'b0;
  end
  
  // ===== Stage 4: Error Reporting =====
  reg timeout_detected;
  
  // Timeout detection logic
  always @(posedge clk) begin
    timeout_detected <= active_and_not_ack && counter_at_max;
  end
  
  // Error flag management
  always @(posedge clk) begin
    if (req_detected)
      timeout_error <= 1'b0;
    else if (timeout_detected)
      timeout_error <= 1'b1;
  end

endmodule