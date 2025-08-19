//SystemVerilog
module multi_bit_parity(
  input [15:0] data_word,
  output [1:0] parity_bits
);
  wire [7:0] lower_half = data_word[7:0];
  wire [7:0] upper_half = data_word[15:8];

  assign parity_bits[0] = (lower_half[0] ^ lower_half[1] ^ lower_half[2] ^ lower_half[3] ^ 
                           lower_half[4] ^ lower_half[5] ^ lower_half[6] ^ lower_half[7]);
  assign parity_bits[1] = (upper_half[0] ^ upper_half[1] ^ upper_half[2] ^ upper_half[3] ^ 
                           upper_half[4] ^ upper_half[5] ^ upper_half[6] ^ upper_half[7]);
endmodule