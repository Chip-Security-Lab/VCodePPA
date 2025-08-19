//SystemVerilog
// SystemVerilog
// Top module instantiating an 8-bit NOT gate module
module not_gate_8bit (
    input wire [7:0] A,
    output wire [7:0] Y
);

  // Instantiate the 8-bit NOT gate array module
  not_gate_array_8bit not_gate_array_inst (
      .A(A),
      .Y(Y)
  );

endmodule

// 8-bit NOT gate array module
// This module performs bitwise NOT operation on an 8-bit input
module not_gate_array_8bit (
    input wire [7:0] A,
    output wire [7:0] Y
);

  // Perform bitwise NOT operation
  assign Y = ~A;

endmodule