//SystemVerilog
// Top-level module
module odd_parity_generator(
  input [7:0] data_input,
  output odd_parity
);

  // Instantiate the parity calculation submodule
  wire parity_result;
  parity_calculator u_parity_calculator (
    .data(data_input),
    .parity(parity_result)
  );

  // Assign the output from the submodule to the top-level output
  assign odd_parity = parity_result;

endmodule

// Submodule for parity calculation
module parity_calculator(
  input [7:0] data,
  output parity
);
  // Calculate odd parity using bitwise XOR
  assign parity = ^data;
endmodule