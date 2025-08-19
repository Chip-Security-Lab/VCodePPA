//SystemVerilog
module mipi_soundwire_formatter #(parameter CHANNELS = 2) (
  input wire clk, reset_n,
  input wire [15:0] pcm_data_in [0:CHANNELS-1],
  input wire data_valid,
  output reg [31:0] soundwire_frame,
  output reg frame_valid
);
  localparam IDLE = 2'b00, HEADER = 2'b01, PAYLOAD = 2'b10, TRAILER = 2'b11;
  
  reg [1:0] state;
  reg [3:0] channel_cnt;
  reg [7:0] frame_counter;
  
  // Simplified frame counter increment logic
  wire [7:0] frame_counter_next;
  
  // Pre-compute constants
  wire [31:0] header_frame = {8'hA5, 8'h00, 8'h00, 8'h00};
  wire [31:0] trailer_frame_base = {24'h000000, 8'h00};
  
  // Optimized frame counter increment
  assign frame_counter_next = frame_counter + 1'b1;
  
  // State transition logic
  wire next_state_idle, next_state_header, next_state_payload, next_state_trailer;
  
  assign next_state_idle = (state == TRAILER) || 
                          ((state == IDLE) && !data_valid);
  
  assign next_state_header = (state == IDLE) && data_valid;
  
  assign next_state_payload = (state == HEADER) || 
                             ((state == PAYLOAD) && (channel_cnt < CHANNELS));
  
  assign next_state_trailer = (state == PAYLOAD) && (channel_cnt >= CHANNELS);
  
  // Channel counter logic
  wire [3:0] channel_cnt_next;
  assign channel_cnt_next = (state == PAYLOAD) ? channel_cnt + 1'b1 : 4'd0;
  
  // Frame data logic
  wire [31:0] frame_data;
  assign frame_data = (state == PAYLOAD) ? {pcm_data_in[channel_cnt], 16'h0000} : 
                      (state == TRAILER) ? {24'h000000, frame_counter} : header_frame;
  
  // Frame valid logic
  wire frame_valid_next;
  assign frame_valid_next = (state == IDLE && data_valid) || 
                           (state == PAYLOAD && channel_cnt < CHANNELS) || 
                           (state == TRAILER);
  
  // Sequential logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      channel_cnt <= 4'd0;
      frame_counter <= 8'd0;
      frame_valid <= 1'b0;
      soundwire_frame <= 32'h0;
    end else begin
      // State transitions
      if (next_state_idle) state <= IDLE;
      else if (next_state_header) state <= HEADER;
      else if (next_state_payload) state <= PAYLOAD;
      else if (next_state_trailer) state <= TRAILER;
      
      // Channel counter update
      channel_cnt <= channel_cnt_next;
      
      // Frame counter update
      if (state == TRAILER) frame_counter <= frame_counter_next;
      
      // Frame data and valid signal
      soundwire_frame <= frame_data;
      frame_valid <= frame_valid_next;
    end
  end
endmodule