//SystemVerilog
module parallel_prefix_parity_calc(
  input clk, rst, bit_in, start,
  output reg parity_done,
  output reg parity_bit
);

  reg [3:0] bit_count;
  reg [3:0] bit_count_buf;
  reg [3:0] bit_buffer;
  reg [3:0] prefix_xor;

  // Parallel prefix XOR computation
  always @(posedge clk) begin
    if (rst || start) begin
      bit_buffer <= 4'd0;
      prefix_xor <= 4'd0;
      bit_count_buf <= 4'd0;
      parity_done <= 1'b0;
      parity_bit <= 1'b0;
    end else if (bit_count_buf < 4'd8) begin
      // Shift in new bit
      bit_buffer <= {bit_buffer[2:0], bit_in};
      
      // Parallel prefix XOR computation
      prefix_xor[0] <= bit_buffer[0];
      prefix_xor[1] <= bit_buffer[0] ^ bit_buffer[1];
      prefix_xor[2] <= bit_buffer[0] ^ bit_buffer[1] ^ bit_buffer[2];
      prefix_xor[3] <= bit_buffer[0] ^ bit_buffer[1] ^ bit_buffer[2] ^ bit_buffer[3];
      
      bit_count_buf <= bit_count_buf + 1'b1;
      parity_done <= (bit_count_buf == 4'd7);
      parity_bit <= prefix_xor[3];
    end
  end

  always @(posedge clk) begin
    bit_count <= bit_count_buf;
  end

endmodule