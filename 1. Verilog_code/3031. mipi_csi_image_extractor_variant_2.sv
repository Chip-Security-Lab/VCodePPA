//SystemVerilog
module mipi_csi_image_extractor (
  input wire clk, reset_n,
  input wire [31:0] packet_data,
  input wire packet_valid, packet_start, packet_end,
  input wire [7:0] packet_type,
  output reg [15:0] pixel_data,
  output reg pixel_valid,
  output reg frame_start, frame_end, line_start, line_end
);

  localparam FRAME_START = 8'h00, LINE_START = 8'h01;
  localparam FRAME_END = 8'h02, LINE_END = 8'h03, RAW_10 = 8'h2B;
  
  reg [2:0] state, state_next;
  reg [31:0] data_buffer, data_buffer_next;
  reg [1:0] pixel_count, pixel_count_next;
  reg [15:0] pixel_data_next;
  reg pixel_valid_next;
  reg frame_start_next, frame_end_next, line_start_next, line_end_next;
  
  wire is_frame_start, is_line_start, is_frame_end, is_line_end, is_raw_data;
  wire [15:0] pixel_data_temp [0:3];
  
  // Pre-compute packet type matches
  assign is_frame_start = packet_start && (packet_type == FRAME_START);
  assign is_line_start = packet_start && (packet_type == LINE_START);
  assign is_frame_end = packet_end && (packet_type == FRAME_END);
  assign is_line_end = packet_end && (packet_type == LINE_END);
  assign is_raw_data = packet_type == RAW_10;
  
  // Pre-compute pixel data
  assign pixel_data_temp[0] = {data_buffer[9:0], 6'b0};
  assign pixel_data_temp[1] = {data_buffer[19:10], 6'b0};
  assign pixel_data_temp[2] = {data_buffer[29:20], 6'b0};
  assign pixel_data_temp[3] = {data_buffer[31:30], 8'b0, 6'b0};

  // Combinational logic for next state
  always @(*) begin
    state_next = state;
    data_buffer_next = data_buffer;
    pixel_count_next = pixel_count;
    pixel_data_next = pixel_data;
    pixel_valid_next = 1'b0;
    frame_start_next = 1'b0;
    frame_end_next = 1'b0;
    line_start_next = 1'b0;
    line_end_next = 1'b0;

    if (packet_valid) begin
      frame_start_next = is_frame_start;
      line_start_next = is_line_start;
      frame_end_next = is_frame_end;
      line_end_next = is_line_end;
      
      if (is_raw_data) begin
        data_buffer_next = packet_data;
        pixel_count_next = 2'd0;
        state_next = 3'd1;
      end
    end
    
    if (state == 3'd1) begin
      pixel_data_next = pixel_data_temp[pixel_count];
      pixel_valid_next = 1'b1;
      pixel_count_next = pixel_count + 1'b1;
      if (pixel_count == 2'd3) 
        state_next = 3'd0;
    end
  end

  // Sequential logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 3'd0;
      data_buffer <= 32'd0;
      pixel_count <= 2'd0;
      pixel_data <= 16'd0;
      pixel_valid <= 1'b0;
      frame_start <= 1'b0;
      frame_end <= 1'b0;
      line_start <= 1'b0;
      line_end <= 1'b0;
    end else begin
      state <= state_next;
      data_buffer <= data_buffer_next;
      pixel_count <= pixel_count_next;
      pixel_data <= pixel_data_next;
      pixel_valid <= pixel_valid_next;
      frame_start <= frame_start_next;
      frame_end <= frame_end_next;
      line_start <= line_start_next;
      line_end <= line_end_next;
    end
  end

endmodule