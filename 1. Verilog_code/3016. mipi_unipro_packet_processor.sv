module mipi_unipro_packet_processor (
  input wire clk, reset_n,
  input wire [7:0] data_in,
  input wire sop, eop, valid_in,
  output reg [15:0] tc_data_out,
  output reg tc_valid_out,
  output reg error_crc
);
  reg [2:0] state;
  reg [15:0] crc;
  reg [7:0] packet_buffer [0:63];
  reg [5:0] byte_count;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 3'd0;
      byte_count <= 6'd0;
      error_crc <= 1'b0;
      tc_valid_out <= 1'b0;
    end else if (valid_in) begin
      case (state)
        3'd0: if (sop) begin state <= 3'd1; byte_count <= 6'd0; end
        3'd1: begin
          packet_buffer[byte_count] <= data_in;
          byte_count <= byte_count + 1'b1;
          if (eop) begin state <= 3'd2; tc_valid_out <= 1'b1; end
        end
        3'd2: begin tc_valid_out <= 1'b0; state <= 3'd0; end
      endcase
    end
  end
endmodule