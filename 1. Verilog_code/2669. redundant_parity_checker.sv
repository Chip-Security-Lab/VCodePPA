module redundant_parity_checker(
  input [7:0] data_in,
  input ext_parity,
  output error_detected
);
  wire parity_a, parity_b, parity_agreement;
  
  // Two different parity implementations for redundancy
  assign parity_a = ^data_in;
  assign parity_b = data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ 
                    data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
  
  // Compare both generated parities
  assign parity_agreement = parity_a == parity_b;
  
  // Error detected if both internal parities agree but differ from external
  assign error_detected = parity_agreement && (parity_a != ext_parity);
endmodule