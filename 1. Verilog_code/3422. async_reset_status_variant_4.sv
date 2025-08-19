//SystemVerilog
//IEEE 1364-2005 Verilog
module async_reset_status (
  input wire clk,
  input wire reset,
  output reg valid,         // Changed from 'req' to 'valid'
  input wire ready,         // Changed from 'ack' to 'ready'
  output reg [3:0] reset_count
);
  
  // Signal to track handshake completion
  reg handshake_complete;
  
  // Valid signal management
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      valid <= 1'b1;  // Assert valid during reset
      handshake_complete <= 1'b0;
    end
    else begin
      if (valid && ready) begin
        // Valid handshake occurred
        if (reset_count == 4'b1111) begin
          // Keep valid high at final count
          valid <= 1'b1;
        end
        else begin
          // Prepare for next data transfer
          valid <= 1'b1;
          handshake_complete <= 1'b1;
        end
      end
      else if (handshake_complete) begin
        // Reset handshake tracking after completion
        handshake_complete <= 1'b0;
      end
    end
  end
  
  // Reset counter logic with Valid-Ready handshake
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      // Asynchronous reset, clear counter
      reset_count <= 4'b0000;
    end
    else if (reset_count != 4'b1111 && valid && ready) begin
      // Only increment when valid handshake occurs and not at max value
      reset_count <= reset_count + 1'b1;
    end
    // Maintain current value when max reached or no valid handshake
  end
  
endmodule