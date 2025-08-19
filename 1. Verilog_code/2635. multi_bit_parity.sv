module multi_bit_parity(
  input [15:0] data_word,
  output [1:0] parity_bits
);
  assign parity_bits[0] = ^data_word[7:0];
  assign parity_bits[1] = ^data_word[15:8];
endmodule