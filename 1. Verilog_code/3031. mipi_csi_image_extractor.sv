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
  
  reg [2:0] state;
  reg [31:0] data_buffer;
  reg [1:0] pixel_count;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 3'd0;
      pixel_valid <= 1'b0;
      frame_start <= 1'b0;
      frame_end <= 1'b0;
      line_start <= 1'b0;
      line_end <= 1'b0;
    end else begin
      pixel_valid <= 1'b0;
      frame_start <= 1'b0;
      frame_end <= 1'b0;
      line_start <= 1'b0;
      line_end <= 1'b0;
      
      if (packet_valid) begin
        if (packet_start && packet_type == FRAME_START) frame_start <= 1'b1;
        else if (packet_start && packet_type == LINE_START) line_start <= 1'b1;
        else if (packet_end && packet_type == FRAME_END) frame_end <= 1'b1;
        else if (packet_end && packet_type == LINE_END) line_end <= 1'b1;
        else if (packet_type == RAW_10) begin
          data_buffer <= packet_data;
          pixel_count <= 2'd0;
          state <= 3'd1;
        end
      end
      
      if (state == 3'd1) begin
        case (pixel_count)
          2'd0: pixel_data <= {data_buffer[9:0], 6'b0};
          2'd1: pixel_data <= {data_buffer[19:10], 6'b0};
          2'd2: pixel_data <= {data_buffer[29:20], 6'b0};
          2'd3: pixel_data <= {data_buffer[31:30], 8'b0, 6'b0};
        endcase
        pixel_valid <= 1'b1;
        pixel_count <= pixel_count + 1'b1;
        if (pixel_count == 2'd3) state <= 3'd0;
      end
    end
  end
endmodule