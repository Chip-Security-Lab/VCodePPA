//SystemVerilog
module adder_8 (
  input logic [7:0] a,
  input logic [7:0] b,
  output logic [7:0] sum
);

  logic [7:0] p; // Propagate signals
  logic [7:0] g; // Generate signals
  logic [8:0] c; // Carries (c[0] is cin, c[8] is cout)

  // Calculate Propagate and Generate signals for each bit
  assign p = a ^ b;
  assign g = a & b;

  // Assume carry-in is 0
  assign c[0] = 1'b0;

  // Calculate carries using Carry-Lookahead logic
  // C[i+1] = G[i] | (P[i] & C[i])
  // Expanded form for C1-C4 (lookahead within lower 4 bits)
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
  assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
  assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);

  // Recursive form for C5-C8 (rippling carry from C4)
  assign c[5] = g[4] | (p[4] & c[4]);
  assign c[6] = g[5] | (p[5] & c[5]);
  assign c[7] = g[6] | (p[6] & c[6]);
  assign c[8] = g[7] | (p[7] & c[7]); // Final carry-out (not connected to output port)

  // Calculate sum bits
  // Sum[i] = P[i] ^ C[i]
  assign sum[0] = p[0] ^ c[0];
  assign sum[1] = p[1] ^ c[1];
  assign sum[2] = p[2] ^ c[2];
  assign sum[3] = p[3] ^ c[3];
  assign sum[4] = p[4] ^ c[4];
  assign sum[5] = p[5] ^ c[5];
  assign sum[6] = p[6] ^ c[6];
  assign sum[7] = p[7] ^ c[7];

endmodule