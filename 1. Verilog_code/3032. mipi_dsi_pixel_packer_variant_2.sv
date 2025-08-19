//SystemVerilog
// Top level module
module mipi_dsi_pixel_packer #(parameter RGB_FMT = 0) (
  input wire clk, reset_n,
  input wire [23:0] pixel_data,
  input wire pixel_valid,
  output reg [31:0] dsi_packet,
  output reg packet_valid
);

  wire [31:0] rgb888_packet;
  wire [31:0] rgb565_packet;
  wire [31:0] rgb666_packed_packet;
  wire [31:0] rgb666_loose_packet;
  wire [31:0] default_packet;
  
  wire rgb888_valid;
  wire rgb565_valid;
  wire rgb666_packed_valid;
  wire rgb666_loose_valid;
  wire default_valid;

  // RGB888 format module
  rgb888_packer rgb888_inst (
    .clk(clk),
    .reset_n(reset_n),
    .pixel_data(pixel_data),
    .pixel_valid(pixel_valid),
    .dsi_packet(rgb888_packet),
    .packet_valid(rgb888_valid)
  );

  // RGB565 format module  
  rgb565_packer rgb565_inst (
    .clk(clk),
    .reset_n(reset_n),
    .pixel_data(pixel_data),
    .pixel_valid(pixel_valid),
    .dsi_packet(rgb565_packet),
    .packet_valid(rgb565_valid)
  );

  // RGB666 packed format module
  rgb666_packed_packer rgb666_packed_inst (
    .clk(clk),
    .reset_n(reset_n),
    .pixel_data(pixel_data),
    .pixel_valid(pixel_valid),
    .dsi_packet(rgb666_packed_packet),
    .packet_valid(rgb666_packed_valid)
  );

  // RGB666 loose format module
  rgb666_loose_packer rgb666_loose_inst (
    .clk(clk),
    .reset_n(reset_n),
    .pixel_data(pixel_data),
    .pixel_valid(pixel_valid),
    .dsi_packet(rgb666_loose_packet),
    .packet_valid(rgb666_loose_valid)
  );

  // Default format module
  default_packer default_inst (
    .clk(clk),
    .reset_n(reset_n),
    .pixel_data(pixel_data),
    .pixel_valid(pixel_valid),
    .dsi_packet(default_packet),
    .packet_valid(default_valid)
  );

  // Output multiplexer
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      dsi_packet <= 32'h0;
      packet_valid <= 1'b0;
    end else begin
      case (RGB_FMT)
        3'd0: begin
          dsi_packet <= rgb888_packet;
          packet_valid <= rgb888_valid;
        end
        3'd1: begin
          dsi_packet <= rgb565_packet;
          packet_valid <= rgb565_valid;
        end
        3'd2: begin
          dsi_packet <= rgb666_packed_packet;
          packet_valid <= rgb666_packed_valid;
        end
        3'd3: begin
          dsi_packet <= rgb666_loose_packet;
          packet_valid <= rgb666_loose_valid;
        end
        default: begin
          dsi_packet <= default_packet;
          packet_valid <= default_valid;
        end
      endcase
    end
  end

endmodule

// RGB888 format submodule
module rgb888_packer (
  input wire clk, reset_n,
  input wire [23:0] pixel_data,
  input wire pixel_valid,
  output reg [31:0] dsi_packet,
  output reg packet_valid
);

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      dsi_packet <= 32'h0;
      packet_valid <= 1'b0;
    end else if (pixel_valid) begin
      dsi_packet <= {8'h00, pixel_data};
      packet_valid <= 1'b1;
    end else begin
      packet_valid <= 1'b0;
    end
  end

endmodule

// RGB565 format submodule
module rgb565_packer (
  input wire clk, reset_n,
  input wire [23:0] pixel_data,
  input wire pixel_valid,
  output reg [31:0] dsi_packet,
  output reg packet_valid
);

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      dsi_packet <= 32'h0;
      packet_valid <= 1'b0;
    end else if (pixel_valid) begin
      dsi_packet <= {16'h0000, pixel_data[23:19], pixel_data[15:10], pixel_data[7:3]};
      packet_valid <= 1'b1;
    end else begin
      packet_valid <= 1'b0;
    end
  end

endmodule

// RGB666 packed format submodule
module rgb666_packed_packer (
  input wire clk, reset_n,
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
      case (pixel_count)
        2'd0: begin
          pixel_buffer[17:0] <= {pixel_data[23:18], pixel_data[15:10], pixel_data[7:2]};
          pixel_count <= 2'd1;
          packet_valid <= 1'b0;
        end
        2'd1: begin
          pixel_buffer[35:18] <= {pixel_data[23:18], pixel_data[15:10], pixel_data[7:2]};
          pixel_count <= 2'd2;
          packet_valid <= 1'b0;
        end
        2'd2: begin
          dsi_packet <= {pixel_data[5:0], pixel_buffer[35:10]};
          pixel_count <= 2'd0;
          packet_valid <= 1'b1;
        end
      endcase
    end else begin
      packet_valid <= 1'b0;
    end
  end

endmodule

// RGB666 loose format submodule
module rgb666_loose_packer (
  input wire clk, reset_n,
  input wire [23:0] pixel_data,
  input wire pixel_valid,
  output reg [31:0] dsi_packet,
  output reg packet_valid
);

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      dsi_packet <= 32'h0;
      packet_valid <= 1'b0;
    end else if (pixel_valid) begin
      dsi_packet <= {8'h00, 2'b00, pixel_data[23:18], 2'b00, 
                     pixel_data[15:10], 2'b00, pixel_data[7:2]};
      packet_valid <= 1'b1;
    end else begin
      packet_valid <= 1'b0;
    end
  end

endmodule

// Default format submodule
module default_packer (
  input wire clk, reset_n,
  input wire [23:0] pixel_data,
  input wire pixel_valid,
  output reg [31:0] dsi_packet,
  output reg packet_valid
);

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      dsi_packet <= 32'h0;
      packet_valid <= 1'b0;
    end else if (pixel_valid) begin
      dsi_packet <= {8'h00, pixel_data};
      packet_valid <= 1'b1;
    end else begin
      packet_valid <= 1'b0;
    end
  end

endmodule