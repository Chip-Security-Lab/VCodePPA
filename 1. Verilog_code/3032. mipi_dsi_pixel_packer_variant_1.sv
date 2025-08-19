//SystemVerilog
module mipi_dsi_pixel_packer #(parameter RGB_FMT = 0) (
  input wire clk, reset_n,
  input wire [23:0] pixel_data,
  input wire pixel_valid,
  output reg [31:0] dsi_packet,
  output reg packet_valid
);

  // Internal registers
  reg [1:0] pixel_count;
  reg [63:0] pixel_buffer;
  reg [23:0] rgb888_data;
  reg [15:0] rgb565_data;
  reg [23:0] rgb666_loose_data;
  reg [31:0] next_dsi_packet;
  reg next_packet_valid;

  // RGB888 format processing
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      rgb888_data <= 24'h0;
    end else if (pixel_valid && RGB_FMT == 0) begin
      rgb888_data <= pixel_data;
    end
  end

  // RGB565 format processing
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      rgb565_data <= 16'h0;
    end else if (pixel_valid && RGB_FMT == 1) begin
      rgb565_data <= {pixel_data[23:19], pixel_data[15:10], pixel_data[7:3]};
    end
  end

  // RGB666_LOOSE format processing
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      rgb666_loose_data <= 24'h0;
    end else if (pixel_valid && RGB_FMT == 3) begin
      rgb666_loose_data <= {pixel_data[23:18], pixel_data[15:10], pixel_data[7:2]};
    end
  end

  // RGB666_PACKED pixel counter
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      pixel_count <= 2'd0;
    end else if (pixel_valid && RGB_FMT == 2) begin
      pixel_count <= (pixel_count == 2'd2) ? 2'd0 : pixel_count + 1'b1;
    end
  end

  // RGB666_PACKED buffer management
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      pixel_buffer <= 64'h0;
    end else if (pixel_valid && RGB_FMT == 2) begin
      case (pixel_count)
        2'd0: pixel_buffer[17:0] <= {pixel_data[23:18], pixel_data[15:10], pixel_data[7:2]};
        2'd1: pixel_buffer[35:18] <= {pixel_data[23:18], pixel_data[15:10], pixel_data[7:2]};
        2'd2: pixel_buffer[53:36] <= {pixel_data[23:18], pixel_data[15:10], pixel_data[7:2]};
      endcase
    end
  end

  // Output packet generation
  always @(*) begin
    case (RGB_FMT)
      0: begin // RGB888
        next_dsi_packet = {8'h00, rgb888_data};
        next_packet_valid = pixel_valid;
      end
      
      1: begin // RGB565
        next_dsi_packet = {16'h0000, rgb565_data};
        next_packet_valid = pixel_valid;
      end
      
      2: begin // RGB666_PACKED
        next_dsi_packet = (pixel_count == 2'd2) ? 
                         {pixel_data[5:0], pixel_buffer[35:10]} : 32'h0;
        next_packet_valid = (pixel_count == 2'd2) && pixel_valid;
      end
      
      3: begin // RGB666_LOOSE
        next_dsi_packet = {8'h00, 2'b00, rgb666_loose_data[23:18], 2'b00,
                          rgb666_loose_data[17:12], 2'b00, rgb666_loose_data[11:6]};
        next_packet_valid = pixel_valid;
      end
      
      default: begin
        next_dsi_packet = {8'h00, rgb888_data};
        next_packet_valid = pixel_valid;
      end
    endcase
  end

  // Output register
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      dsi_packet <= 32'h0;
      packet_valid <= 1'b0;
    end else begin
      dsi_packet <= next_dsi_packet;
      packet_valid <= next_packet_valid;
    end
  end

endmodule