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
  
  // Pipeline stage 1 registers
  reg [31:0] data_buffer_stage1;
  reg [7:0] packet_type_stage1;
  reg packet_valid_stage1;
  reg frame_start_stage1, frame_end_stage1;
  reg line_start_stage1, line_end_stage1;
  reg raw_data_valid_stage1;
  
  // Pipeline stage 2 registers
  reg [31:0] data_buffer_stage2;
  reg [2:0] pixel_count_stage2;
  reg frame_start_stage2, frame_end_stage2;
  reg line_start_stage2, line_end_stage2;
  reg raw_data_valid_stage2;
  
  // Pipeline stage 3 registers
  reg [15:0] pixel_data_stage3;
  reg pixel_valid_stage3;
  reg frame_start_stage3, frame_end_stage3;
  reg line_start_stage3, line_end_stage3;

  // Stage 1: Packet processing with optimized combinational logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      data_buffer_stage1 <= 32'd0;
      packet_type_stage1 <= 8'd0;
      packet_valid_stage1 <= 1'b0;
      frame_start_stage1 <= 1'b0;
      frame_end_stage1 <= 1'b0;
      line_start_stage1 <= 1'b0;
      line_end_stage1 <= 1'b0;
      raw_data_valid_stage1 <= 1'b0;
    end else begin
      packet_valid_stage1 <= packet_valid;
      packet_type_stage1 <= packet_type;
      
      if (packet_valid) begin
        frame_start_stage1 <= packet_start && (packet_type == FRAME_START);
        line_start_stage1 <= packet_start && (packet_type == LINE_START);
        frame_end_stage1 <= packet_end && (packet_type == FRAME_END);
        line_end_stage1 <= packet_end && (packet_type == LINE_END);
        
        if (packet_type == RAW_10) begin
          data_buffer_stage1 <= packet_data;
          raw_data_valid_stage1 <= 1'b1;
        end else begin
          raw_data_valid_stage1 <= 1'b0;
        end
      end else begin
        frame_start_stage1 <= 1'b0;
        frame_end_stage1 <= 1'b0;
        line_start_stage1 <= 1'b0;
        line_end_stage1 <= 1'b0;
        raw_data_valid_stage1 <= 1'b0;
      end
    end
  end

  // Stage 2: Pixel extraction with optimized counter logic
  reg [2:0] next_pixel_count;
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      data_buffer_stage2 <= 32'd0;
      pixel_count_stage2 <= 3'd0;
      frame_start_stage2 <= 1'b0;
      frame_end_stage2 <= 1'b0;
      line_start_stage2 <= 1'b0;
      line_end_stage2 <= 1'b0;
      raw_data_valid_stage2 <= 1'b0;
    end else begin
      data_buffer_stage2 <= data_buffer_stage1;
      frame_start_stage2 <= frame_start_stage1;
      frame_end_stage2 <= frame_end_stage1;
      line_start_stage2 <= line_start_stage1;
      line_end_stage2 <= line_end_stage1;
      raw_data_valid_stage2 <= raw_data_valid_stage1;
      
      next_pixel_count = (raw_data_valid_stage1) ? 3'd0 :
                        (raw_data_valid_stage2 && pixel_count_stage2 < 3'd3) ? 
                        pixel_count_stage2 + 1'b1 : pixel_count_stage2;
      pixel_count_stage2 <= next_pixel_count;
    end
  end

  // Stage 3: Pixel output with optimized data selection
  reg [15:0] next_pixel_data;
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      pixel_data_stage3 <= 16'd0;
      pixel_valid_stage3 <= 1'b0;
      frame_start_stage3 <= 1'b0;
      frame_end_stage3 <= 1'b0;
      line_start_stage3 <= 1'b0;
      line_end_stage3 <= 1'b0;
    end else begin
      frame_start_stage3 <= frame_start_stage2;
      frame_end_stage3 <= frame_end_stage2;
      line_start_stage3 <= line_start_stage2;
      line_end_stage3 <= line_end_stage2;
      
      if (raw_data_valid_stage2) begin
        case (pixel_count_stage2)
          3'd0: next_pixel_data = {data_buffer_stage2[9:0], 6'b0};
          3'd1: next_pixel_data = {data_buffer_stage2[19:10], 6'b0};
          3'd2: next_pixel_data = {data_buffer_stage2[29:20], 6'b0};
          3'd3: next_pixel_data = {data_buffer_stage2[31:30], 8'b0, 6'b0};
        endcase
        pixel_data_stage3 <= next_pixel_data;
        pixel_valid_stage3 <= 1'b1;
      end else begin
        pixel_valid_stage3 <= 1'b0;
      end
    end
  end

  // Output assignment with registered outputs
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      pixel_data <= 16'd0;
      pixel_valid <= 1'b0;
      frame_start <= 1'b0;
      frame_end <= 1'b0;
      line_start <= 1'b0;
      line_end <= 1'b0;
    end else begin
      pixel_data <= pixel_data_stage3;
      pixel_valid <= pixel_valid_stage3;
      frame_start <= frame_start_stage3;
      frame_end <= frame_end_stage3;
      line_start <= line_start_stage3;
      line_end <= line_end_stage3;
    end
  end

endmodule