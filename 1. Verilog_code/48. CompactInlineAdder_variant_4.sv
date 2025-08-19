//SystemVerilog
// Top module for the 4-bit adder
module add1 (
  input [3:0] x,
  input [3:0] y,
  output [4:0] s
);

  // Internal wires to connect submodules
  wire [3:0] w_p;          // Propagate signals
  wire [3:0] w_g;          // Generate signals
  wire [4:0] w_carries;    // Calculated carries (w_carries[0] is carry_in)
  wire [3:0] w_sum_bits;   // Sum bits

  // Assume carry-in is 0 for this specific adder instance
  wire w_carry_in = 1'b0;

  // Instantiate PG generation block
  pg_gen_block u_pg_gen (
    .x(x),
    .y(y),
    .p(w_p),
    .g(w_g)
  );

  // Instantiate CLA block
  cla_block u_cla (
    .p(w_p),
    .g(w_g),
    .carry_in(w_carry_in), // Connect to assumed carry-in
    .carries(w_carries)    // Output calculated carries
  );

  // Instantiate Sum generation block
  // The sum bits s[i] use carry c[i] (carries_in[i])
  sum_gen_block u_sum_gen (
    .p(w_p),
    .carries_in(w_carries[3:0]), // Use c[0]..c[3] from CLA output
    .sum_bits(w_sum_bits)      // Output sum bits
  );

  // Combine carry-out (c[4]) and sum bits for the final result
  assign s = {w_carries[4], w_sum_bits};

endmodule

// Module to generate Propagate and Generate signals for a 4-bit block
module pg_gen_block (
  input [3:0] x,
  input [3:0] y,
  output [3:0] p, // Propagate signals (p[i] = x[i] ^ y[i])
  output [3:0] g  // Generate signals (g[i] = x[i] & y[i])
);
  // p[i] = x[i] ^ y[i]
  assign p = x ^ y;
  // g[i] = x[i] & y[i]
  assign g = x & y;
endmodule

// Module for Carry Lookahead Logic for a 4-bit block
module cla_block (
  input [3:0] p,        // Propagate signals
  input [3:0] g,        // Generate signals
  input       carry_in, // Carry input to the block (c[0])
  output [4:0] carries  // Calculated carries (carries[0] = carry_in, carries[1..4] are calculated)
);
  // Internal wires for intermediate carries
  wire c0, c1, c2, c3, c4;

  assign c0 = carry_in;

  // Calculate carries using recursive look-ahead logic: c[i+1] = g[i] | (p[i] & c[i])
  assign c1 = g[0] | (p[0] & c0);
  assign c2 = g[1] | (p[1] & c1);
  assign c3 = g[2] | (p[2] & c2);
  assign c4 = g[3] | (p[3] & c3);

  // Output carries, including the input carry
  assign carries = {c4, c3, c2, c1, c0};

endmodule

// Module to generate Sum bits for a 4-bit block
module sum_gen_block (
  input [3:0] p,          // Propagate signals
  input [3:0] carries_in, // Carries into each bit position (c[0]..c[3])
  output [3:0] sum_bits    // Calculated sum bits (sum_bits[i] = p[i] ^ carries_in[i])
);
  // sum_bits[i] = p[i] ^ carries_in[i]
  assign sum_bits = p ^ carries_in;
endmodule