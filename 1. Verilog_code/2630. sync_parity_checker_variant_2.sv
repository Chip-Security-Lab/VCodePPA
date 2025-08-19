//SystemVerilog
module sync_parity_checker(
  input clk, rst,
  input [7:0] data,
  input parity_in,
  output reg error,
  output reg [3:0] error_count
);

  // Carry Lookahead Adder implementation
  wire [7:0] data_xor;
  wire parity_check;
  
  // Generate propagate signals (XOR chain)
  assign data_xor[0] = data[0] ^ parity_in;
  assign data_xor[1] = data[1] ^ data_xor[0];
  assign data_xor[2] = data[2] ^ data_xor[1];
  assign data_xor[3] = data[3] ^ data_xor[2];
  assign data_xor[4] = data[4] ^ data_xor[3];
  assign data_xor[5] = data[5] ^ data_xor[4];
  assign data_xor[6] = data[6] ^ data_xor[5];
  assign data_xor[7] = data[7] ^ data_xor[6];
  
  // Final parity check
  assign parity_check = data_xor[7];

  always @(posedge clk) begin
    if (rst) begin
      error <= 1'b0;
      error_count <= 4'd0;
    end else if (parity_check) begin
      error <= 1'b1;
      error_count <= error_count + 1'b1;
    end else begin
      error <= 1'b0;
    end
  end
endmodule