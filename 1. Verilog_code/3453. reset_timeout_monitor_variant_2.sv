//SystemVerilog
module reset_timeout_monitor (
  input  wire clk,                // System clock
  input  wire reset_n,            // Active low reset
  output reg  reset_timeout_error // Timeout error flag
);

  // Reduced bit width for timeout counter - optimization for area
  reg [6:0] timeout_counter;
  
  // Pre-computed comparison threshold to avoid full-width comparison
  localparam [6:0] TIMEOUT_THRESHOLD = 7'h7F;
  
  // Fast timeout detection using optimized comparison
  wire timeout_detected;
  
  // Optimized counter with early termination logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      timeout_counter <= 7'd0;
    end else if (timeout_counter < TIMEOUT_THRESHOLD) begin
      // Range check is more efficient than equality check
      timeout_counter <= timeout_counter + 7'd1;
    end
  end

  // Optimized threshold detection using single comparison
  // This improves timing by reducing logic levels
  assign timeout_detected = (timeout_counter == TIMEOUT_THRESHOLD);

  // Error flag generation with clear edge-case handling
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      reset_timeout_error <= 1'b0;
    end else if (timeout_detected) begin
      reset_timeout_error <= 1'b1;
    end
    // Once set, error remains until reset
  end

endmodule