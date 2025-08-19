//SystemVerilog

// Submodule for calculating parity
module parity_calculator(
  input [31:0] data_in,
  output parity_out
);
  assign parity_out = ^data_in; // Calculate parity
endmodule

// Top-level module
module hier_parity_gen(
  input [31:0] wide_data,
  output parity
);
  // Instantiate the parity calculator submodule
  parity_calculator u_parity_calculator (
    .data_in(wide_data),
    .parity_out(parity)
  );
endmodule