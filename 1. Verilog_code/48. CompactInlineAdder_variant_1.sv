//SystemVerilog
// SystemVerilog

// Top-level module for a 4-bit adder using hierarchical bit slices
module add1 (
  input  [3:0] x,
  input  [3:0] y,
  output [4:0] s
);

  // Internal signals for sum bits and carry chain
  wire [3:0] sum_bits;
  wire [4:0] carry_chain; // carry_chain[0] is cin, carry_chain[4] is cout

  // Set the initial carry-in to 0 for simple addition
  assign carry_chain[0] = 1'b0;

  // Instantiate 4 adder bit slices
  // Each slice calculates sum and carry-out for one bit position
  adder_bit_slice slice0 (
    .x_i    (x[0]),
    .y_i    (y[0]),
    .cin_i  (carry_chain[0]),
    .sum_i  (sum_bits[0]),
    .cout_i (carry_chain[1])
  );

  adder_bit_slice slice1 (
    .x_i    (x[1]),
    .y_i    (y[1]),
    .cin_i  (carry_chain[1]),
    .sum_i  (sum_bits[1]),
    .cout_i (carry_chain[2])
  );

  adder_bit_slice slice2 (
    .x_i    (x[2]),
    .y_i    (y[2]),
    .cin_i  (carry_chain[2]),
    .sum_i  (sum_bits[2]),
    .cout_i (carry_chain[3])
  );

  adder_bit_slice slice3 (
    .x_i    (x[3]),
    .y_i    (y[3]),
    .cin_i  (carry_chain[3]),
    .sum_i  (sum_bits[3]),
    .cout_i (carry_chain[4])
  );

  // Assemble the final 5-bit sum output
  // s[4] is the final carry-out (carry_chain[4])
  // s[3:0] are the sum bits from the slices
  assign s = {carry_chain[4], sum_bits[3:0]};

endmodule


// Submodule: adder_bit_slice
// Performs addition logic (sum and carry-out) for a single bit position.
// Implements the Generate/Propagate/Carry logic for one bit.
module adder_bit_slice (
  input  x_i,    // Input bit x
  input  y_i,    // Input bit y
  input  cin_i,  // Carry-in from the previous bit
  output sum_i,  // Sum output bit
  output cout_i  // Carry-out to the next bit
);

  // Calculate Generate (g) and Propagate (p) signals
  // g = x & y (carry is generated within this bit)
  // p = x ^ y (carry is propagated through this bit)
  wire generate_sig_i  = x_i & y_i;
  wire propagate_sig_i = x_i ^ y_i;

  // Calculate the carry-out
  // cout = g | (p & cin)
  assign cout_i = generate_sig_i | (propagate_sig_i & cin_i);

  // Calculate the sum bit
  // sum = p ^ cin
  assign sum_i = propagate_sig_i ^ cin_i;

endmodule