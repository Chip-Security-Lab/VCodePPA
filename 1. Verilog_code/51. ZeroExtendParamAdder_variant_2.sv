//SystemVerilog
// Top Module: cat_add_hierarchical
// Hierarchical implementation of zero-extended addition.
// Decomposes the operation into zero extension and addition sub-modules.
module cat_add_hierarchical #(parameter N=4)(
  input [N-1:0] in1, in2,
  output [N:0] out
);

  // Internal wires to connect sub-modules
  wire [N:0] in1_ext;
  wire [N:0] in2_ext;

  // Instantiate zero extender for in1
  zero_extender #( .N(N) )
  u_zero_extender_in1 (
    .data_in(in1),
    .data_out(in1_ext)
  );

  // Instantiate zero extender for in2
  zero_extender #( .N(N) )
  u_zero_extender_in2 (
    .data_in(in2),
    .data_out(in2_ext)
  );

  // Instantiate adder
  adder #( .WIDTH(N+1) ) // Adder operates on N+1 bit values
  u_adder (
    .op1(in1_ext),
    .op2(in2_ext),
    .sum(out)
  );

endmodule

// Submodule: zero_extender
// Performs zero extension of an N-bit input to N+1 bits.
module zero_extender #(parameter N=4)(
  input [N-1:0] data_in,
  output [N:0] data_out
);
  assign data_out = {1'b0, data_in};
endmodule

// Submodule: adder
// Performs addition of two inputs of specified width.
module adder #(parameter WIDTH=5)(
  input [WIDTH-1:0] op1, op2,
  output [WIDTH-1:0] sum
);
  assign sum = op1 + op2;
endmodule