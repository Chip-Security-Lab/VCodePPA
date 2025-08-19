//SystemVerilog
module parity_gen(
  input [3:0] data,
  output [2:0] parity
);
  assign parity[0] = data[0] ^ data[1] ^ data[3];
  assign parity[1] = data[0] ^ data[2] ^ data[3];
  assign parity[2] = data[1] ^ data[2] ^ data[3];
endmodule

module data_encoder(
  input [3:0] data,
  output [3:0] encoded_data
);
  assign encoded_data = data; // Simplified assignment
endmodule

module hamming_code_gen(
  input [3:0] data_in,
  output [6:0] hamming_out
);
  wire [2:0] parity_bits;
  wire [3:0] encoded_data;

  parity_gen parity_unit(
    .data(data_in),
    .parity(parity_bits)
  );

  data_encoder encoder_unit(
    .data(data_in),
    .encoded_data(encoded_data)
  );

  assign hamming_out = {parity_bits[2], encoded_data[3:1], parity_bits[1:0]}; // Concatenated assignment
endmodule