//SystemVerilog
module matrix_parity_gen(
  input [15:0] data_matrix,
  output [3:0] row_parity,
  output [3:0] col_parity
);
  // Row parity calculation using reduction XOR operator
  assign row_parity = {^data_matrix[15:12], ^data_matrix[11:8], ^data_matrix[7:4], ^data_matrix[3:0]};
  
  // Column parity calculation using transpose and concatenation
  assign col_parity = {
    data_matrix[12] ^ data_matrix[8] ^ data_matrix[4] ^ data_matrix[0],
    data_matrix[13] ^ data_matrix[9] ^ data_matrix[5] ^ data_matrix[1],
    data_matrix[14] ^ data_matrix[10] ^ data_matrix[6] ^ data_matrix[2],
    data_matrix[15] ^ data_matrix[11] ^ data_matrix[7] ^ data_matrix[3]
  };
endmodule