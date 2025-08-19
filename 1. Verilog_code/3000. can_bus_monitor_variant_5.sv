//SystemVerilog
module can_bus_monitor(
  input wire clk, rst_n,
  input wire can_rx, can_tx,
  input wire frame_valid, error_detected,
  input wire [10:0] rx_id,
  input wire [7:0] rx_data [0:7],
  input wire [3:0] rx_dlc,
  output reg [15:0] frames_received,
  output reg [15:0] errors_detected,
  output reg [15:0] bus_load_percent,
  output reg [7:0] last_error_type
);
  reg [31:0] total_bits, active_bits;
  reg prev_frame_valid, prev_error;
  
  // Reset logic for counters
  always @(negedge rst_n) begin
    if (!rst_n) begin
      frames_received <= 16'h0;
      errors_detected <= 16'h0;
      bus_load_percent <= 16'h0;
      last_error_type <= 8'h0;
    end
  end
  
  // Reset logic for tracking variables
  always @(negedge rst_n) begin
    if (!rst_n) begin
      total_bits <= 32'h0;
      active_bits <= 32'h0;
      prev_frame_valid <= 1'b0;
      prev_error <= 1'b0;
    end
  end
  
  // Edge detection registers
  always @(posedge clk) begin
    if (rst_n) begin
      prev_frame_valid <= frame_valid;
      prev_error <= error_detected;
    end
  end
  
  // Frame counter logic
  always @(posedge clk) begin
    if (rst_n && !prev_frame_valid && frame_valid) begin
      frames_received <= frames_received + 16'h1;
    end
  end
  
  // Error detection and classification logic
  always @(posedge clk) begin
    if (rst_n && !prev_error && error_detected) begin
      errors_detected <= errors_detected + 16'h1;
    end
  end

  // Error type capture
  always @(posedge clk) begin
    if (rst_n && !prev_error && error_detected) begin
      // Error type classification logic would go here
      // For now, using a simple value based on rx_id
      last_error_type <= rx_id[7:0];
    end
  end
  
  // Total bits counter
  always @(posedge clk) begin
    if (rst_n) begin
      total_bits <= total_bits + 32'h1;
    end
  end
  
  // Active bits counter
  always @(posedge clk) begin
    if (rst_n && !can_rx) begin
      active_bits <= active_bits + 32'h1;
    end
  end
  
  // Bus load calculation
  always @(posedge clk) begin
    if (rst_n && total_bits >= 32'd1000) begin
      bus_load_percent <= (active_bits * 16'd100) / total_bits;
      total_bits <= 32'h0;
      active_bits <= 32'h0;
    end
  end
endmodule