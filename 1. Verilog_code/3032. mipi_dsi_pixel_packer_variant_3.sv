//SystemVerilog
module mipi_dsi_pixel_packer #(parameter RGB_FMT = 0) (
  input wire clk, 
  input wire reset_n,
  input wire [23:0] pixel_data,
  input wire pixel_valid,
  output reg [31:0] dsi_packet,
  output reg packet_valid
);

  localparam IDLE = 3'd0;
  localparam RGB888 = 3'd1;
  localparam RGB565 = 3'd2;
  localparam RGB666_PACKED = 3'd3;
  localparam RGB666_LOOSE = 3'd4;

  reg [1:0] pixel_count;
  reg [2:0] state;
  reg [63:0] pixel_buffer;
  reg [31:0] next_dsi_packet;
  reg next_packet_valid;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      pixel_count <= 2'd0;
      packet_valid <= 1'b0;
      dsi_packet <= 32'h0;
      pixel_buffer <= 64'h0;
      next_dsi_packet <= 32'h0;
      next_packet_valid <= 1'b0;
    end else begin
      next_packet_valid <= 1'b0;
      
      if (pixel_valid && RGB_FMT == 0) begin
        next_dsi_packet <= {8'h00, pixel_data};
        next_packet_valid <= 1'b1;
      end
      
      if (pixel_valid && RGB_FMT == 1) begin
        next_dsi_packet <= {16'h0000, pixel_data[23:19], pixel_data[15:10], pixel_data[7:3]};
        next_packet_valid <= 1'b1;
      end
      
      if (pixel_valid && RGB_FMT == 2 && pixel_count == 2'd0) begin
        pixel_buffer[17:0] <= {pixel_data[23:18], pixel_data[15:10], pixel_data[7:2]};
        pixel_count <= 2'd1;
      end
      
      if (pixel_valid && RGB_FMT == 2 && pixel_count == 2'd1) begin
        pixel_buffer[35:18] <= {pixel_data[23:18], pixel_data[15:10], pixel_data[7:2]};
        pixel_count <= 2'd2;
      end
      
      if (pixel_valid && RGB_FMT == 2 && pixel_count == 2'd2) begin
        next_dsi_packet <= {pixel_data[5:0], pixel_buffer[35:10]};
        pixel_count <= 2'd0;
        next_packet_valid <= 1'b1;
      end
      
      if (pixel_valid && RGB_FMT == 2 && pixel_count != 2'd0 && pixel_count != 2'd1 && pixel_count != 2'd2) begin
        pixel_count <= 2'd0;
      end
      
      if (pixel_valid && RGB_FMT == 3) begin
        next_dsi_packet <= {8'h00, 2'b00, pixel_data[23:18], 2'b00, 
                           pixel_data[15:10], 2'b00, pixel_data[7:2]};
        next_packet_valid <= 1'b1;
      end
      
      if (pixel_valid && RGB_FMT != 0 && RGB_FMT != 1 && RGB_FMT != 2 && RGB_FMT != 3) begin
        next_dsi_packet <= {8'h00, pixel_data};
        next_packet_valid <= 1'b1;
      end
      
      dsi_packet <= next_dsi_packet;
      packet_valid <= next_packet_valid;
    end
  end

endmodule