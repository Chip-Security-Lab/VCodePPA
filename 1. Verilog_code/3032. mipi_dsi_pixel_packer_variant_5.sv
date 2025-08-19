//SystemVerilog
module mipi_dsi_pixel_packer #(parameter RGB_FMT = 0) (
  input wire clk, reset_n,
  input wire [23:0] pixel_data,
  input wire pixel_valid,
  output reg [31:0] dsi_packet,
  output reg packet_valid
);

  reg [1:0] pixel_count_stage1, pixel_count_stage2;
  reg [2:0] state_stage1, state_stage2;
  reg [63:0] pixel_buffer_stage1, pixel_buffer_stage2;
  reg [23:0] pixel_data_stage1;
  reg pixel_valid_stage1;
  reg [31:0] dsi_packet_stage1;
  reg packet_valid_stage1;

  // Stage 1: Input and Format Selection
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state_stage1 <= 3'd0;
      pixel_count_stage1 <= 2'd0;
      pixel_buffer_stage1 <= 64'h0;
      pixel_data_stage1 <= 24'h0;
      pixel_valid_stage1 <= 1'b0;
    end else begin
      pixel_data_stage1 <= pixel_data;
      pixel_valid_stage1 <= pixel_valid;
      
      if (pixel_valid) begin
        case (RGB_FMT)
          0: begin // RGB888
            dsi_packet_stage1 <= {8'h00, pixel_data};
            packet_valid_stage1 <= 1'b1;
          end
          
          1: begin // RGB565
            dsi_packet_stage1 <= {16'h0000, 
                                pixel_data[23:19], pixel_data[15:10], pixel_data[7:3]};
            packet_valid_stage1 <= 1'b1;
          end
          
          2: begin // RGB666_PACKED
            if (pixel_count_stage1 == 0) begin
              pixel_buffer_stage1[17:0] <= {pixel_data[23:18], pixel_data[15:10], pixel_data[7:2]};
              pixel_count_stage1 <= 2'd1;
              packet_valid_stage1 <= 1'b0;
            end else if (pixel_count_stage1 == 1) begin
              pixel_buffer_stage1[35:18] <= {pixel_data[23:18], pixel_data[15:10], pixel_data[7:2]};
              pixel_count_stage1 <= 2'd2;
              packet_valid_stage1 <= 1'b0;
            end else begin
              dsi_packet_stage1 <= {pixel_data[5:0], pixel_buffer_stage1[35:10]};
              pixel_count_stage1 <= 2'd0;
              packet_valid_stage1 <= 1'b1;
            end
          end
          
          3: begin // RGB666_LOOSE
            dsi_packet_stage1 <= {8'h00, 2'b00, pixel_data[23:18], 2'b00, 
                               pixel_data[15:10], 2'b00, pixel_data[7:2]};
            packet_valid_stage1 <= 1'b1;
          end
          
          default: begin
            dsi_packet_stage1 <= {8'h00, pixel_data};
            packet_valid_stage1 <= 1'b1;
          end
        endcase
      end else begin
        packet_valid_stage1 <= 1'b0;
      end
    end
  end

  // Stage 2: Output Register
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      dsi_packet <= 32'h0;
      packet_valid <= 1'b0;
      state_stage2 <= 3'd0;
      pixel_count_stage2 <= 2'd0;
      pixel_buffer_stage2 <= 64'h0;
    end else begin
      dsi_packet <= dsi_packet_stage1;
      packet_valid <= packet_valid_stage1;
      state_stage2 <= state_stage1;
      pixel_count_stage2 <= pixel_count_stage1;
      pixel_buffer_stage2 <= pixel_buffer_stage1;
    end
  end

endmodule