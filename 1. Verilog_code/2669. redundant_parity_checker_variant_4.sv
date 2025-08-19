//SystemVerilog
module redundant_parity_checker(
  input [7:0] data_in,
  input ext_parity,
  output error_detected
);

  // Simplified parity calculation using XOR tree
  wire [3:0] xor_stage1;
  wire [1:0] xor_stage2;
  wire parity;
  
  // First stage XOR
  assign xor_stage1[0] = data_in[0] ^ data_in[1];
  assign xor_stage1[1] = data_in[2] ^ data_in[3];
  assign xor_stage1[2] = data_in[4] ^ data_in[5];
  assign xor_stage1[3] = data_in[6] ^ data_in[7];
  
  // Second stage XOR
  assign xor_stage2[0] = xor_stage1[0] ^ xor_stage1[1];
  assign xor_stage2[1] = xor_stage1[2] ^ xor_stage1[3];
  
  // Final parity
  assign parity = xor_stage2[0] ^ xor_stage2[1];
  
  // Error detection using optimized expression
  assign error_detected = (parity != ext_parity);

endmodule