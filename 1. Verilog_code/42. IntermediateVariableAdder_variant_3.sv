//SystemVerilog
// one_bit_full_adder: Top-level module for a 1-bit full adder.
// This module instantiates sub-modules for sum and carry calculations,
// demonstrating functional decomposition.
module one_bit_full_adder (
    input wire i_a,    // First input bit
    input wire i_b,    // Second input bit
    input wire i_cin,  // Carry input bit
    output wire o_sum, // Output sum bit
    output wire o_cout // Output carry bit
);

  // Instantiate the sum calculation logic sub-module.
  // This module computes the XOR of the three inputs.
  one_bit_sum_logic sum_logic_inst (
    .i_a   (i_a),   // Connect first input
    .i_b   (i_b),   // Connect second input
    .i_cin (i_cin), // Connect carry input
    .o_sum (o_sum)  // Connect to the sum output
  );

  // Instantiate the carry calculation logic sub-module.
  // This module computes the carry-out based on the inputs.
  one_bit_carry_logic carry_logic_inst (
    .i_a    (i_a),    // Connect first input
    .i_b    (i_b),    // Connect second input
    .i_cin  (i_cin),  // Connect carry input
    .o_cout (o_cout)  // Connect to the carry output
  );

endmodule

// one_bit_sum_logic: Calculates the sum bit for a 1-bit full adder.
// This module implements the XOR logic for the sum output (a XOR b XOR cin).
// It is a functional sub-module for the sum calculation.
module one_bit_sum_logic (
    input wire i_a,    // First input bit
    input wire i_b,    // Second input bit
    input wire i_cin,  // Carry input bit
    output wire o_sum  // Output sum bit (i_a ^ i_b ^ i_cin)
);

  assign o_sum = i_a ^ i_b ^ i_cin;

endmodule

// one_bit_carry_logic: Calculates the carry-out bit for a 1-bit full adder.
// This module implements the logic for the carry output ((a AND b) OR (cin AND (a XOR b))).
// It is a functional sub-module for the carry calculation.
module one_bit_carry_logic (
    input wire i_a,    // First input bit
    input wire i_b,    // Second input bit
    input wire i_cin,  // Carry input bit
    output wire o_cout // Output carry bit ((i_a & i_b) | (i_cin & (i_a ^ i_b)))
);

  assign o_cout = (i_a & i_b) | (i_cin & (i_a ^ i_b));

endmodule