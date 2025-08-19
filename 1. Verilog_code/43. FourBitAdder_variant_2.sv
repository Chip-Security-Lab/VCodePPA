//SystemVerilog
module adder_11 (input [3:0] a, input [3:0] b, output [4:0] sum);

  // Internal signals for propagate (p) and generate (g)
  wire [3:0] p;
  wire [3:0] g;

  // Initial P and G signals for each bit position
  assign p = a ^ b;
  assign g = a & b;

  // Internal signals for carries (c[0] is input carry, c[1]..c[4] are intermediate/output carries)
  wire [4:0] c;

  // Input carry is 0 for simple addition (a + b)
  assign c[0] = 1'b0;

  // Parallel Prefix Adder Logic (Kogge-Stone structure for N=4)

  // Level 1 P and G (Distance 1)
  wire [3:0] p1, g1;
  // Bit 0: identity
  assign p1[0] = p[0];
  assign g1[0] = g[0];
  // Bit 1: combines (1,1) and (0,0) -> (1,0)
  assign p1[1] = p[1] & p[0];
  assign g1[1] = g[1] | (p[1] & g[0]);
  // Bit 2: combines (2,2) and (1,1) -> (2,1)
  assign p1[2] = p[2] & p[1];
  assign g1[2] = g[2] | (p[2] & g[1]);
  // Bit 3: combines (3,3) and (2,2) -> (3,2)
  assign p1[3] = p[3] & p[2];
  assign g1[3] = g[3] | (p[3] & g[2]);

  // Level 2 P and G (Distance 2)
  wire [3:0] p2, g2;
  // Bit 0: identity
  assign p2[0] = p1[0];
  assign g2[0] = g1[0];
  // Bit 1: identity
  assign p2[1] = p1[1];
  assign g2[1] = g1[1];
  // Bit 2: combines (2,1) and (0,0) -> (2,0)
  assign p2[2] = p1[2] & p[0]; // Uses P[2:1] and P[0:0]
  assign g2[2] = g1[2] | (p1[2] & g[0]); // Uses G[2:1], P[2:1], and G[0:0]
  // Bit 3: combines (3,2) and (1,0) -> (3,0)
  assign p2[3] = p1[3] & p1[1]; // Uses P[3:2] and P[1:0]
  assign g2[3] = g1[3] | (p1[3] & g1[1]); // Uses G[3:2], P[3:2], and G[1:0]

  // Assign carries based on final prefix generate signals G[i:0]
  // C[i+1] = G[i:0] for C[0]=0
  assign c[1] = g[0];     // Carry into bit 1 is G[0:0]
  assign c[2] = g1[1];    // Carry into bit 2 is G[1:0]
  assign c[3] = g2[2];    // Carry into bit 3 is G[2:0]
  assign c[4] = g2[3];    // Carry out (carry into bit 4) is G[3:0]

  // Compute sum bits
  // Sum[i] = P[i] ^ C[i]
  wire [3:0] sum_bits;
  assign sum_bits[0] = p[0] ^ c[0]; // c[0] is 0, so sum_bits[0] = p[0]
  assign sum_bits[1] = p[1] ^ c[1];
  assign sum_bits[2] = p[2] ^ c[2];
  assign sum_bits[3] = p[3] ^ c[3];

  // Combine carry-out and sum bits to form the final sum
  assign sum = {c[4], sum_bits};

endmodule