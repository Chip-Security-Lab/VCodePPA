//SystemVerilog
// Top-level module
module mipi_dsi_pixel_packer #(parameter RGB_FMT = 0) (
  input wire clk, 
  input wire reset_n,
  input wire [23:0] pixel_data,
  input wire pixel_valid,
  output wire [31:0] dsi_packet,
  output wire packet_valid
);
  wire [31:0] dsi_packet_rgb888, dsi_packet_rgb565, dsi_packet_rgb666_packed, dsi_packet_rgb666_loose;
  wire packet_valid_rgb888, packet_valid_rgb565, packet_valid_rgb666_packed, packet_valid_rgb666_loose;
  
  rgb888_handler rgb888_inst (
    .clk(clk),
    .reset_n(reset_n),
    .pixel_data(pixel_data),
    .pixel_valid(pixel_valid),
    .dsi_packet(dsi_packet_rgb888),
    .packet_valid(packet_valid_rgb888)
  );
  
  rgb565_handler rgb565_inst (
    .clk(clk),
    .reset_n(reset_n),
    .pixel_data(pixel_data),
    .pixel_valid(pixel_valid),
    .dsi_packet(dsi_packet_rgb565),
    .packet_valid(packet_valid_rgb565)
  );
  
  rgb666_packed_handler rgb666_packed_inst (
    .clk(clk),
    .reset_n(reset_n),
    .pixel_data(pixel_data),
    .pixel_valid(pixel_valid),
    .dsi_packet(dsi_packet_rgb666_packed),
    .packet_valid(packet_valid_rgb666_packed)
  );
  
  rgb666_loose_handler rgb666_loose_inst (
    .clk(clk),
    .reset_n(reset_n),
    .pixel_data(pixel_data),
    .pixel_valid(pixel_valid),
    .dsi_packet(dsi_packet_rgb666_loose),
    .packet_valid(packet_valid_rgb666_loose)
  );
  
  reg [31:0] dsi_packet_reg;
  reg packet_valid_reg;
  
  always @(*) begin
    if (RGB_FMT == 0) begin
      dsi_packet_reg = dsi_packet_rgb888;
      packet_valid_reg = packet_valid_rgb888;
    end else if (RGB_FMT == 1) begin
      dsi_packet_reg = dsi_packet_rgb565;
      packet_valid_reg = packet_valid_rgb565;
    end else if (RGB_FMT == 2) begin
      dsi_packet_reg = dsi_packet_rgb666_packed;
      packet_valid_reg = packet_valid_rgb666_packed;
    end else if (RGB_FMT == 3) begin
      dsi_packet_reg = dsi_packet_rgb666_loose;
      packet_valid_reg = packet_valid_rgb666_loose;
    end else begin
      dsi_packet_reg = dsi_packet_rgb888;
      packet_valid_reg = packet_valid_rgb888;
    end
  end
  
  assign dsi_packet = dsi_packet_reg;
  assign packet_valid = packet_valid_reg;
endmodule

// RGB888 format handler
module rgb888_handler (
  input wire clk,
  input wire reset_n,
  input wire [23:0] pixel_data,
  input wire pixel_valid,
  output reg [31:0] dsi_packet,
  output reg packet_valid
);
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      packet_valid <= 1'b0;
      dsi_packet <= 32'h0;
    end else if (pixel_valid) begin
      dsi_packet <= {8'h00, pixel_data};
      packet_valid <= 1'b1;
    end else begin
      packet_valid <= 1'b0;
    end
  end
endmodule

// RGB565 format handler
module rgb565_handler (
  input wire clk,
  input wire reset_n,
  input wire [23:0] pixel_data,
  input wire pixel_valid,
  output reg [31:0] dsi_packet,
  output reg packet_valid
);
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      packet_valid <= 1'b0;
      dsi_packet <= 32'h0;
    end else if (pixel_valid) begin
      dsi_packet <= {16'h0000, 
                    pixel_data[23:19], pixel_data[15:10], pixel_data[7:3]};
      packet_valid <= 1'b1;
    end else begin
      packet_valid <= 1'b0;
    end
  end
endmodule

// RGB666 packed format handler
module rgb666_packed_handler (
  input wire clk,
  input wire reset_n,
  input wire [23:0] pixel_data,
  input wire pixel_valid,
  output reg [31:0] dsi_packet,
  output reg packet_valid
);
  reg [1:0] pixel_count;
  reg [35:0] pixel_buffer;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      pixel_count <= 2'd0;
      packet_valid <= 1'b0;
      dsi_packet <= 32'h0;
      pixel_buffer <= 36'h0;
    end else if (pixel_valid) begin
      if (pixel_count == 0) begin
        pixel_buffer[17:0] <= {pixel_data[23:18], pixel_data[15:10], pixel_data[7:2]};
        pixel_count <= 2'd1;
        packet_valid <= 1'b0;
      end else if (pixel_count == 1) begin
        pixel_buffer[35:18] <= {pixel_data[23:18], pixel_data[15:10], pixel_data[7:2]};
        pixel_count <= 2'd2;
        packet_valid <= 1'b0;
      end else begin
        dsi_packet <= {pixel_data[5:0], pixel_buffer[35:10]};
        pixel_count <= 2'd0;
        packet_valid <= 1'b1;
      end
    end else begin
      packet_valid <= 1'b0;
    end
  end
endmodule

// RGB666 loose format handler
module rgb666_loose_handler (
  input wire clk,
  input wire reset_n,
  input wire [23:0] pixel_data,
  input wire pixel_valid,
  output reg [31:0] dsi_packet,
  output reg packet_valid
);
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      packet_valid <= 1'b0;
      dsi_packet <= 32'h0;
    end else if (pixel_valid) begin
      dsi_packet <= {8'h00, 2'b00, pixel_data[23:18], 2'b00, 
                     pixel_data[15:10], 2'b00, pixel_data[7:2]};
      packet_valid <= 1'b1;
    end else begin
      packet_valid <= 1'b0;
    end
  end
endmodule