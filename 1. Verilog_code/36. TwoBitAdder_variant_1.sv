//SystemVerilog
//------------------------------------------------------------------------------
// Module: full_adder
// Description: Single-bit full adder
// Inputs:
//   a_bit: First input bit
//   b_bit: Second input bit
//   c_in:  Carry-in bit
// Outputs:
//   sum_bit: Sum output bit
//   c_out:   Carry-out bit
//------------------------------------------------------------------------------
module full_adder (
  input  a_bit,
  input  b_bit,
  input  c_in,
  output sum_bit,
  output c_out
);

  // Propagate and Generate signals
  wire p = a_bit ^ b_bit;
  wire g = a_bit & b_bit;

  // Calculate sum and carry-out
  assign sum_bit = p ^ c_in;
  assign c_out   = g | (p & c_in);

endmodule

//------------------------------------------------------------------------------
// Module: adder_4
// Description: 2-bit ripple-carry adder using full_adder submodules
// Inputs:
//   a: 2-bit first operand
//   b: 2-bit second operand
// Outputs:
//   sum: 3-bit sum (includes carry-out)
//------------------------------------------------------------------------------
module adder_4 (
  input  [1:0] a,
  input  [1:0] b,
  output [2:0] sum
);

  // Internal carry signals between full adders
  wire c0 = 1'b0; // Carry-in for the LSB full adder (always 0 for simple adder)
  wire c1;       // Carry-out of bit 0, Carry-in to bit 1
  wire c2;       // Carry-out of bit 1 (final carry)

  // Instantiate the full adder for the LSB (bit 0)
  full_adder fa_bit0 (
    .a_bit   (a[0]),
    .b_bit   (b[0]),
    .c_in    (c0),
    .sum_bit (sum[0]),
    .c_out   (c1)
  );

  // Instantiate the full adder for the MSB (bit 1)
  full_adder fa_bit1 (
    .a_bit   (a[1]),
    .b_bit   (b[1]),
    .c_in    (c1),
    .sum_bit (sum[1]),
    .c_out   (c2)
  );

  // The most significant bit of the sum is the final carry-out
  assign sum[2] = c2;

endmodule