//SystemVerilog
module odd_parity_gen(
  input [7:0] data_input,
  output odd_parity
);
  // Optimized XOR tree with reduced logic depth
  wire [1:0] level1;
  wire level2;
  
  // First level optimized to process 4 bits at once
  assign level1[0] = data_input[0] ^ data_input[1] ^ data_input[2] ^ data_input[3];
  assign level1[1] = data_input[4] ^ data_input[5] ^ data_input[6] ^ data_input[7];
  
  // Final level combines results
  assign level2 = level1[0] ^ level1[1];
  
  // Direct odd parity calculation
  assign odd_parity = level2;
endmodule