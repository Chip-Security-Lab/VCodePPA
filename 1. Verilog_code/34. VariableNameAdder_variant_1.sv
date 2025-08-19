//SystemVerilog
module adder_2 (
  input [7:0] x,
  input [7:0] y,
  output [7:0] z
);

  // Internal wires for sum bits and carry bits
  wire [7:0] sum_bits;
  wire [8:0] carry_bits; // carry_bits[0] is carry-in, carry_bits[1] to carry_bits[7] are intermediate, carry_bits[8] is carry-out

  // Set the initial carry-in to 0 for simple addition
  assign carry_bits[0] = 1'b0;

  // Implement 8 full adder stages by unrolling the loop

  // Full adder logic for bit 0
  assign sum_bits[0] = x[0] ^ y[0] ^ carry_bits[0];
  assign carry_bits[1] = (x[0] & y[0]) | ((x[0] ^ y[0]) & carry_bits[0]);

  // Full adder logic for bit 1
  assign sum_bits[1] = x[1] ^ y[1] ^ carry_bits[1];
  assign carry_bits[2] = (x[1] & y[1]) | ((x[1] ^ y[1]) & carry_bits[1]);

  // Full adder logic for bit 2
  assign sum_bits[2] = x[2] ^ y[2] ^ carry_bits[2];
  assign carry_bits[3] = (x[2] & y[2]) | ((x[2] ^ y[2]) & carry_bits[2]);

  // Full adder logic for bit 3
  assign sum_bits[3] = x[3] ^ y[3] ^ carry_bits[3];
  assign carry_bits[4] = (x[3] & y[3]) | ((x[3] ^ y[3]) & carry_bits[3]);

  // Full adder logic for bit 4
  assign sum_bits[4] = x[4] ^ y[4] ^ carry_bits[4];
  assign carry_bits[5] = (x[4] & y[4]) | ((x[4] ^ y[4]) & carry_bits[4]);

  // Full adder logic for bit 5
  assign sum_bits[5] = x[5] ^ y[5] ^ carry_bits[5];
  assign carry_bits[6] = (x[5] & y[5]) | ((x[5] ^ y[5]) & carry_bits[5]);

  // Full adder logic for bit 6
  assign sum_bits[6] = x[6] ^ y[6] ^ carry_bits[6];
  assign carry_bits[7] = (x[6] & y[6]) | ((x[6] ^ y[6]) & carry_bits[6]);

  // Full adder logic for bit 7
  assign sum_bits[7] = x[7] ^ y[7] ^ carry_bits[7];
  assign carry_bits[8] = (x[7] & y[7]) | ((x[7] ^ y[7]) & carry_bits[7]);


  // Assign the resulting sum bits to the output
  assign z = sum_bits;

  // The final carry_bits[8] is the carry-out of the 8-bit addition,
  // but it is not part of the specified output 'z',
  // which matches the behavior of a simple 8-bit '+' operator result.

endmodule