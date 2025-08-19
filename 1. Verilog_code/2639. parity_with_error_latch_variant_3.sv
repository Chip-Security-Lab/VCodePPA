//SystemVerilog
module parity_with_error_latch_req_ack(
  input clk, 
  input rst, 
  input clear_error,
  input [7:0] data,
  input parity_in,
  output reg error_latched,
  output reg req, // Request signal
  input ack // Acknowledge signal
);

  wire current_error;
  assign current_error = (^data) ^ parity_in;

  // Always block for error latching
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      error_latched <= 1'b0; // Reset error latch
      req <= 1'b0; // Reset request
    end else if (clear_error) begin
      error_latched <= 1'b0; // Clear error latch
      req <= 1'b0; // Reset request
    end else if (current_error) begin
      error_latched <= 1'b1; // Latch error if current error detected
      req <= 1'b1; // Assert request when error is detected
    end else if (ack) begin
      req <= 1'b0; // Deassert request when acknowledged
    end
  end

endmodule