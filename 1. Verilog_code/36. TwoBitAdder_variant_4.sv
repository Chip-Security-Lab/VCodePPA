//SystemVerilog
// Top-level module for the 2-bit adder
// Instantiates sub-modules for each bit's logic
module adder_4 (
    input  logic [1:0] a,
    input  logic [1:0] b,
    output logic [2:0] sum
);

  // Internal carry signal between bit 0 and bit 1
  logic c1;

  // Instantiate Bit 0 Adder
  // Handles the LSB logic and generates the carry into bit 1
  bit_0_adder u_bit_0_adder (
    .a0 (a[0]),
    .b0 (b[0]),
    .s0 (sum[0]), // sum[0] is the sum output of bit 0
    .c1 (c1)      // c1 is the carry output of bit 0 (carry-in for bit 1)
  );

  // Instantiate Bit 1 Adder
  // Handles the logic for bit 1 and generates the final carry-out (sum[2])
  bit_1_adder u_bit_1_adder (
    .a1 (a[1]),
    .b1 (b[1]),
    .c1 (c1),      // Carry-in from bit 0
    .s1 (sum[1]),  // sum[1] is the sum output of bit 1
    .c2 (sum[2])   // c2 is the carry output of bit 1 (sum[2])
  );

endmodule

// Sub-module for the Least Significant Bit (Bit 0) of the adder
// Calculates sum[0] and carry-out (c1)
module bit_0_adder (
    input  logic a0,
    input  logic b0,
    output logic s0,
    output logic c1
);

  // Sum calculation for bit 0 (equivalent to a half adder sum since c_in is 0)
  assign s0 = a0 ^ b0;

  // Carry-out calculation for bit 0 (carry-in for bit 1)
  assign c1 = a0 & b0;

endmodule

// Sub-module for Bit 1 of the adder
// Calculates sum[1] and carry-out (c2) based on inputs and carry-in (c1)
module bit_1_adder (
    input  logic a1,
    input  logic b1,
    input  logic c1, // Carry-in from bit 0
    output logic s1,
    output logic c2  // Carry-out (sum[2])
);

  // Generate and Propagate signals for this bit
  logic g1, p1;

  assign g1 = a1 & b1;
  assign p1 = a1 | b1;

  // Sum calculation for bit 1
  assign s1 = a1 ^ b1 ^ c1;

  // Carry-out calculation for bit 1 (using generate/propagate)
  assign c2 = g1 | (p1 & c1);

endmodule