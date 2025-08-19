//SystemVerilog
module matrix_parity_gen(
  input clk,
  input rst_n,
  input [15:0] data_matrix,
  input valid,
  output ready,
  output reg [3:0] row_parity,
  output reg [3:0] col_parity,
  output reg valid_out,
  input ready_out
);
  
  // Internal signals
  reg [3:0] row_parity_next;
  reg [3:0] col_parity_next;
  reg valid_pending;
  
  // Handshaking control logic
  assign ready = !valid_pending || (valid_pending && valid_out && ready_out);
  
  // Parity calculation
  always @(*) begin
    // Row parity calculation
    row_parity_next[0] = ^data_matrix[3:0];
    row_parity_next[1] = ^data_matrix[7:4];
    row_parity_next[2] = ^data_matrix[11:8];
    row_parity_next[3] = ^data_matrix[15:12];
    
    // Column parity calculation
    col_parity_next[0] = data_matrix[0] ^ data_matrix[4] ^ data_matrix[8] ^ data_matrix[12];
    col_parity_next[1] = data_matrix[1] ^ data_matrix[5] ^ data_matrix[9] ^ data_matrix[13];
    col_parity_next[2] = data_matrix[2] ^ data_matrix[6] ^ data_matrix[10] ^ data_matrix[14];
    col_parity_next[3] = data_matrix[3] ^ data_matrix[7] ^ data_matrix[11] ^ data_matrix[15];
  end
  
  // Main state machine
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      row_parity <= 4'b0;
      col_parity <= 4'b0;
      valid_out <= 1'b0;
      valid_pending <= 1'b0;
    end
    else begin
      if (valid && ready) begin
        // Capture new data
        row_parity <= row_parity_next;
        col_parity <= col_parity_next;
        valid_pending <= 1'b1;
        valid_out <= 1'b1;
      end
      else if (valid_out && ready_out) begin
        // Data accepted by downstream
        valid_out <= 1'b0;
        valid_pending <= 1'b0;
      end
    end
  end
  
endmodule