module mipi_dsi_pixel_packer #(parameter RGB_FMT = 0) (
  input wire clk, reset_n,
  input wire [23:0] pixel_data, // R[23:16], G[15:8], B[7:0]
  input wire pixel_valid,
  output reg [31:0] dsi_packet,
  output reg packet_valid
);
  // RGB_FMT: 0=RGB888, 1=RGB565, 2=RGB666_PACKED, 3=RGB666_LOOSE
  
  reg [1:0] pixel_count;
  reg [2:0] state;
  reg [63:0] pixel_buffer;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 3'd0;
      pixel_count <= 2'd0;
      packet_valid <= 1'b0;
      dsi_packet <= 32'h0;
      pixel_buffer <= 64'h0;
    end else if (pixel_valid) begin
      case (RGB_FMT)
        0: begin // RGB888
          dsi_packet <= {8'h00, pixel_data};
          packet_valid <= 1'b1;
        end
        
        1: begin // RGB565
          dsi_packet <= {16'h0000, 
                        pixel_data[23:19], pixel_data[15:10], pixel_data[7:3]};
          packet_valid <= 1'b1;
        end
        
        2: begin // RGB666_PACKED
          if (pixel_count == 0) begin
            pixel_buffer[17:0] <= {pixel_data[23:18], pixel_data[15:10], pixel_data[7:2]};
            pixel_count <= 2'd1;
            packet_valid <= 1'b0;
          end else if (pixel_count == 1) begin
            pixel_buffer[35:18] <= {pixel_data[23:18], pixel_data[15:10], pixel_data[7:2]};
            pixel_count <= 2'd2;
            packet_valid <= 1'b0;
          end else begin // pixel_count == 2
            dsi_packet <= {pixel_data[5:0], pixel_buffer[35:10]};
            pixel_count <= 2'd0;
            packet_valid <= 1'b1;
          end
        end
        
        3: begin // RGB666_LOOSE
          dsi_packet <= {8'h00, 2'b00, pixel_data[23:18], 2'b00, 
                         pixel_data[15:10], 2'b00, pixel_data[7:2]};
          packet_valid <= 1'b1;
        end
        
        default: begin
          dsi_packet <= {8'h00, pixel_data};
          packet_valid <= 1'b1;
        end
      endcase
    end else begin
      packet_valid <= 1'b0;
    end
  end
endmodule