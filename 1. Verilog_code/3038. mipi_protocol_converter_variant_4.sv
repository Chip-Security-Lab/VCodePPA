//SystemVerilog
module mipi_protocol_converter (
  input wire clk, reset_n,
  input wire [31:0] src_data,
  input wire src_valid,
  output reg src_ready,
  input wire [3:0] src_protocol,
  input wire [3:0] dst_protocol,
  output reg [31:0] dst_data,
  output reg dst_valid,
  input wire dst_ready,
  output reg conversion_error
);

  reg [3:0] state;
  reg [7:0] header_type;
  reg [15:0] data_count;
  
  // Pre-computed protocol conversion tables
  reg [7:0] csi_to_dsi [0:4];
  reg [7:0] dsi_to_csi [0:4];
  
  // Protocol conversion logic
  wire [7:0] converted_header;
  wire is_csi_to_dsi;
  wire is_dsi_to_csi;
  wire is_valid_conversion;
  
  // Protocol type detection
  assign is_csi_to_dsi = (src_protocol == 4'h0) && (dst_protocol == 4'h1);
  assign is_dsi_to_csi = (src_protocol == 4'h1) && (dst_protocol == 4'h0);
  assign is_valid_conversion = is_csi_to_dsi || is_dsi_to_csi;
  
  // Header conversion logic
  assign converted_header = 
    (is_csi_to_dsi) ? 
      (src_data[7:0] == 8'h00) ? 8'h01 :
      (src_data[7:0] == 8'h01) ? 8'h02 :
      (src_data[7:0] == 8'h02) ? 8'h03 :
      (src_data[7:0] == 8'h03) ? 8'h04 :
      (src_data[7:0] == 8'h1A) ? 8'h3E : 8'hFF :
    (is_dsi_to_csi) ?
      (src_data[7:0] == 8'h01) ? 8'h00 :
      (src_data[7:0] == 8'h02) ? 8'h01 :
      (src_data[7:0] == 8'h03) ? 8'h02 :
      (src_data[7:0] == 8'h04) ? 8'h03 :
      (src_data[7:0] == 8'h3E) ? 8'h1A : 8'hFF :
    8'hFF;
  
  // State machine
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 4'd0;
      conversion_error <= 1'b0;
      dst_valid <= 1'b0;
      dst_data <= 32'h0;
      src_ready <= 1'b0;
    end else begin
      if (src_valid && src_ready) begin
        case (state)
          4'd0: begin
            header_type <= src_data[7:0];
            if (!is_valid_conversion || converted_header == 8'hFF) begin
              conversion_error <= 1'b1;
              dst_valid <= 1'b0;
            end else begin
              dst_data <= {src_data[31:8], converted_header};
              dst_valid <= 1'b1;
              conversion_error <= 1'b0;
              state <= 4'd1;
            end
          end
          default: begin
            dst_data <= src_data;
            dst_valid <= 1'b1;
            conversion_error <= 1'b0;
          end
        endcase
      end else if (dst_valid && dst_ready) begin
        dst_valid <= 1'b0;
      end
      
      // Ready signal logic
      src_ready <= !dst_valid || (dst_valid && dst_ready);
    end
  end
endmodule