module can_error_detector(
  input wire clk, rst_n,
  input wire can_rx, bit_sample_point,
  input wire tx_mode,
  output reg bit_error, stuff_error, form_error, crc_error,
  output reg [7:0] error_count
);
  reg [2:0] consecutive_bits;
  reg expected_bit, received_bit;
  reg [14:0] crc_calc, crc_received;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      error_count <= 0;
      bit_error <= 0; stuff_error <= 0; form_error <= 0; crc_error <= 0;
    end else if (bit_sample_point) begin
      if (tx_mode && (can_rx != expected_bit)) begin
        bit_error <= 1;
        error_count <= error_count + 1;
      end
      consecutive_bits <= (can_rx == received_bit) ? consecutive_bits + 1 : 0;
      stuff_error <= (consecutive_bits >= 5);
    end
  end
endmodule