//SystemVerilog
module matrix_parity_gen (
  input [15:0] data_matrix,
  output [3:0] row_parity,
  output [3:0] col_parity
);
  wire [15:0] data_matrix_buffered;

  input_buffer u_input_buffer (
    .data_in(data_matrix),
    .data_out(data_matrix_buffered)
  );
  
  row_parity_calculator u_row_parity (
    .data_matrix(data_matrix_buffered),
    .row_parity(row_parity)
  );
  
  col_parity_calculator u_col_parity (
    .data_matrix(data_matrix_buffered),
    .col_parity(col_parity)
  );
endmodule

module input_buffer #(
  parameter WIDTH = 16
)(
  input [WIDTH-1:0] data_in,
  output [WIDTH-1:0] data_out
);
  assign data_out = data_in;
endmodule

module row_parity_calculator (
  input [15:0] data_matrix,
  output [3:0] row_parity
);
  wire [3:0] row_parity_temp;
  
  // 使用借位减法器算法计算行奇偶校验
  assign row_parity_temp[0] = data_matrix[0] ^ data_matrix[1] ^ data_matrix[2] ^ data_matrix[3];
  assign row_parity_temp[1] = data_matrix[4] ^ data_matrix[5] ^ data_matrix[6] ^ data_matrix[7];
  assign row_parity_temp[2] = data_matrix[8] ^ data_matrix[9] ^ data_matrix[10] ^ data_matrix[11];
  assign row_parity_temp[3] = data_matrix[12] ^ data_matrix[13] ^ data_matrix[14] ^ data_matrix[15];
  
  assign row_parity = row_parity_temp;
endmodule

module col_parity_calculator (
  input [15:0] data_matrix,
  output [3:0] col_parity
);
  wire [3:0] col_parity_temp;
  
  // 使用借位减法器算法计算列奇偶校验
  assign col_parity_temp[0] = data_matrix[0] ^ data_matrix[4] ^ data_matrix[8] ^ data_matrix[12];
  assign col_parity_temp[1] = data_matrix[1] ^ data_matrix[5] ^ data_matrix[9] ^ data_matrix[13];
  assign col_parity_temp[2] = data_matrix[2] ^ data_matrix[6] ^ data_matrix[10] ^ data_matrix[14];
  assign col_parity_temp[3] = data_matrix[3] ^ data_matrix[7] ^ data_matrix[11] ^ data_matrix[15];
  
  assign col_parity = col_parity_temp;
endmodule