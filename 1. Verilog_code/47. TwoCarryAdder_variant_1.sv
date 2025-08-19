//SystemVerilog
// Submodule: Half Adder
// Calculates sum and carry for two input bits
module half_adder (
  input wire x,
  input wire y,
  output wire s, // sum output (x XOR y)
  output wire c  // carry output (x AND y)
);
  assign s = x ^ y;
  assign c = x & y;
endmodule

// Top module: Full Adder built from simplified boolean expressions
// Adds three input bits (a, b, c_in) to produce a sum and a carry
module adder_15 (
  input wire a,
  input wire b,
  input wire c_in,
  output wire sum,
  output wire carry
);

  // Internal signal for the intermediate sum (a XOR b)
  // Used for calculating the final sum
  wire s1;

  // Calculate intermediate sum s1 = a XOR b
  // This is the sum of the first two bits, equivalent to the first half adder's sum output
  assign s1 = a ^ b;

  // Calculate final sum = s1 XOR c_in = (a XOR b) XOR c_in
  // This is the sum of the intermediate sum and the carry-in, equivalent to the second half adder's sum output
  assign sum = s1 ^ c_in;

  // Calculate final carry using the standard simplified boolean expression
  // The original carry was (a & b) | ((a ^ b) & c_in)
  // This is equivalent to the standard full adder carry: (a AND b) OR (a AND c_in) OR (b AND c_in)
  // Using the standard form often results in a more optimized gate-level implementation
  assign carry = (a & b) | (a & c_in) | (b & c_in);

endmodule