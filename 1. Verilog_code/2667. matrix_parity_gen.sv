module matrix_parity_gen(
  input [15:0] data_matrix,
  output [3:0] row_parity,
  output [3:0] col_parity
);
  // Row parity calculation
  assign row_parity[0] = ^data_matrix[3:0];
  assign row_parity[1] = ^data_matrix[7:4];
  assign row_parity[2] = ^data_matrix[11:8];
  assign row_parity[3] = ^data_matrix[15:12];
  
  // Column parity calculation
  assign col_parity[0] = data_matrix[0] ^ data_matrix[4] ^ 
                         data_matrix[8] ^ data_matrix[12];
  assign col_parity[1] = data_matrix[1] ^ data_matrix[5] ^ 
                         data_matrix[9] ^ data_matrix[13];
  assign col_parity[2] = data_matrix[2] ^ data_matrix[6] ^ 
                         data_matrix[10] ^ data_matrix[14];
  assign col_parity[3] = data_matrix[3] ^ data_matrix[7] ^ 
                         data_matrix[11] ^ data_matrix[15];
endmodule