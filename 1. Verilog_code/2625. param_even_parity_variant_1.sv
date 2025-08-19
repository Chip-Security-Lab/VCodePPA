//SystemVerilog
// Brent-Kung Adder Implementation in Verilog
module brent_kung_adder (
  input [7:0] a,
  input [7:0] b,
  output [7:0] sum,
  output carry_out
);
  wire [7:0] p; // propagate
  wire [7:0] g; // generate
  wire [7:0] c; // carry

  // Generate and propagate signals
  assign p = a ^ b; // propagate
  assign g = a & b; // generate

  // Carry generation using Brent-Kung method
  assign c[0] = 1'b0; // c0 is always 0 (no carry-in)
  assign c[1] = g[0]; // c1 = g0
  assign c[2] = g[1] | (p[1] & g[0]); // c2 = g1 + (p1 * g0)
  assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]); // c3 = g2 + (p2 * g1) + (p2 * p1 * g0)
  assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]); // c4
  assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]); // c5
  assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]); // c6
  assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]); // c7

  // Sum calculation
  assign sum = p ^ c; // sum = propagate XOR carry
  assign carry_out = c[7]; // final carry out

endmodule