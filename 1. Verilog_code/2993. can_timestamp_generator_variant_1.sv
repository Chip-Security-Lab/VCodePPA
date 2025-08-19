//SystemVerilog
module can_timestamp_generator(
  input wire clk, rst_n,
  input wire can_rx_edge, can_frame_start, can_frame_end,
  output reg [31:0] current_timestamp,
  output reg [31:0] frame_timestamp,
  output reg timestamp_valid
);
  reg [15:0] prescaler_count;
  reg [31:0] next_current_timestamp;
  reg [31:0] next_frame_timestamp;
  reg next_timestamp_valid;
  localparam PRESCALER = 1000; // For microsecond resolution
  
  // Calculate next timestamp value and prescaler count
  always @(*) begin
    next_current_timestamp = current_timestamp;
    if (prescaler_count >= PRESCALER - 1)
      next_current_timestamp = current_timestamp + 1;
  end
  
  // Determine next frame timestamp value
  always @(*) begin
    next_frame_timestamp = frame_timestamp;
    if (can_frame_start)
      next_frame_timestamp = current_timestamp;
  end
  
  // Determine next timestamp valid signal
  always @(*) begin
    next_timestamp_valid = 0;
    if (can_frame_end)
      next_timestamp_valid = 1;
  end
  
  // Sequential logic for registers
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_timestamp <= 0;
      frame_timestamp <= 0;
      timestamp_valid <= 0;
      prescaler_count <= 0;
    end else begin
      // Update outputs
      current_timestamp <= next_current_timestamp;
      frame_timestamp <= next_frame_timestamp;
      timestamp_valid <= next_timestamp_valid;
      
      // Update prescaler
      if (prescaler_count >= PRESCALER - 1)
        prescaler_count <= 0;
      else
        prescaler_count <= prescaler_count + 1;
    end
  end
endmodule