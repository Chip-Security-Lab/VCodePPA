module mipi_csi_packet_decoder (
  input wire clk, rst_n,
  input wire [31:0] packet_data,
  input wire packet_valid,
  output reg [7:0] packet_type,
  output reg [15:0] word_count,
  output reg [7:0] virtual_channel,
  output reg is_long_packet,
  output reg decode_error
);
  reg [1:0] state;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= 2'b00;
      packet_type <= 8'h00;
      word_count <= 16'h0000;
      virtual_channel <= 8'h00;
      is_long_packet <= 1'b0;
      decode_error <= 1'b0;
    end else if (packet_valid) begin
      packet_type <= packet_data[7:0];
      virtual_channel <= packet_data[15:8] & 8'h03;
      word_count <= packet_data[31:16];
      is_long_packet <= (packet_data[7:0] > 8'h0F);
      decode_error <= (packet_data[7:0] == 8'h00);
    end
  end
endmodule