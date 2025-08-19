//SystemVerilog
module mipi_protocol_converter (
  input wire clk, reset_n,
  input wire [31:0] src_data,
  input wire src_valid,
  input wire [3:0] src_protocol,
  input wire [3:0] dst_protocol,
  output reg [31:0] dst_data,
  output reg dst_valid,
  output reg conversion_error
);

  reg [3:0] state;
  reg [7:0] header_type;
  reg [15:0] data_count;
  reg [7:0] converted_header_reg;
  wire [7:0] converted_header;
  wire is_csi_to_dsi;
  wire is_dsi_to_csi;
  
  assign is_csi_to_dsi = (src_protocol == 4'd0) && (dst_protocol == 4'd1);
  assign is_dsi_to_csi = (src_protocol == 4'd1) && (dst_protocol == 4'd0);
  
  assign converted_header = 
    is_csi_to_dsi ? (
      (src_data[7:0] == 8'h00) ? 8'h01 :
      (src_data[7:0] == 8'h01) ? 8'h02 :
      (src_data[7:0] == 8'h02) ? 8'h03 :
      (src_data[7:0] == 8'h03) ? 8'h04 :
      (src_data[7:0] == 8'h1A) ? 8'h3E : 8'hFF
    ) : is_dsi_to_csi ? (
      (src_data[7:0] == 8'h01) ? 8'h00 :
      (src_data[7:0] == 8'h02) ? 8'h01 :
      (src_data[7:0] == 8'h03) ? 8'h02 :
      (src_data[7:0] == 8'h04) ? 8'h03 :
      (src_data[7:0] == 8'h3E) ? 8'h1A : 8'hFF
    ) : 8'hFF;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 4'd0;
      conversion_error <= 1'b0;
      dst_valid <= 1'b0;
      converted_header_reg <= 8'h00;
    end else begin
      converted_header_reg <= converted_header;
      
      if (src_valid) begin
        if (state == 4'd0) begin
          header_type <= src_data[7:0];
          conversion_error <= (converted_header_reg == 8'hFF);
          dst_data <= {src_data[31:8], converted_header_reg};
          dst_valid <= 1'b1;
          state <= 4'd1;
        end else begin
          dst_data <= src_data;
          dst_valid <= 1'b1;
        end
      end else begin
        dst_valid <= 1'b0;
      end
    end
  end

endmodule