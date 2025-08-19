//SystemVerilog
module parity_gen_with_enable(
  input clk, enable,
  input [15:0] data_word,
  output reg parity_result
);
  reg parity_bit;
  reg [15:0] data_word_buf; // Buffer for load balancing

  // Buffering high fanout signal
  always @(posedge clk) begin
    if (enable)
      data_word_buf <= data_word; // Registering data_word
  end
  
  always @(*) begin
    parity_bit = data_word_buf[0] ^ data_word_buf[1] ^ data_word_buf[2] ^ data_word_buf[3] ^
                 data_word_buf[4] ^ data_word_buf[5] ^ data_word_buf[6] ^ data_word_buf[7] ^
                 data_word_buf[8] ^ data_word_buf[9] ^ data_word_buf[10] ^ data_word_buf[11] ^
                 data_word_buf[12] ^ data_word_buf[13] ^ data_word_buf[14] ^ data_word_buf[15];
  end
  
  always @(posedge clk) begin
    if (enable)
      parity_result <= parity_bit;
  end
endmodule