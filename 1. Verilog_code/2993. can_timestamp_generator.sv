module can_timestamp_generator(
  input wire clk, rst_n,
  input wire can_rx_edge, can_frame_start, can_frame_end,
  output reg [31:0] current_timestamp,
  output reg [31:0] frame_timestamp,
  output reg timestamp_valid
);
  reg [15:0] prescaler_count;
  localparam PRESCALER = 1000; // For microsecond resolution
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_timestamp <= 0;
      frame_timestamp <= 0;
      timestamp_valid <= 0;
      prescaler_count <= 0;
    end else begin
      timestamp_valid <= 0;
      
      prescaler_count <= prescaler_count + 1;
      if (prescaler_count >= PRESCALER - 1) begin
        prescaler_count <= 0;
        current_timestamp <= current_timestamp + 1;
      end
      
      if (can_frame_start) begin
        frame_timestamp <= current_timestamp;
      end
      
      if (can_frame_end) begin
        timestamp_valid <= 1;
      end
    end
  end
endmodule