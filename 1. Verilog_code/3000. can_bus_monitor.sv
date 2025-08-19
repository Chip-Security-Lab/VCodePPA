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
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frames_received <= 0;
      errors_detected <= 0;
      bus_load_percent <= 0;
      last_error_type <= 0;
      total_bits <= 0;
      active_bits <= 0;
    end else begin
      prev_frame_valid <= frame_valid;
      prev_error <= error_detected;
      
      // Count frames and errors
      if (!prev_frame_valid && frame_valid)
        frames_received <= frames_received + 1;
        
      if (!prev_error && error_detected) begin
        errors_detected <= errors_detected + 1;
        // last_error_type would be set based on error flags
      end
      
      // Calculate bus load
      total_bits <= total_bits + 1;
      if (!can_rx) active_bits <= active_bits + 1;
      
      if (total_bits >= 32'd1000) begin
        bus_load_percent <= (active_bits * 100) / total_bits;
        total_bits <= 0;
        active_bits <= 0;
      end
    end
  end
endmodule