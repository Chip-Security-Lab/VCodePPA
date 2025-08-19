//SystemVerilog
module adder_11 (input [3:0] a, input [3:0] b, output [4:0] sum);

  // Internal signals for Han-Carlson Adder
  wire [3:0] p; // Propagate bits: p[i] = a[i] ^ b[i]
  wire [3:0] g; // Generate bits:  g[i] = a[i] & b[i]

  // Prefix tree intermediate signals (Han-Carlson for N=4)
  // Level 1 (distance 1)
  wire G_1_0, P_1_0; // Group (1:0)
  wire G_1_2, P_1_2; // Group (3:2)

  // Level 2 (distance 2)
  wire G_2_0, P_2_0; // Group (3:0) - Black cell output
  wire G_2_1;       // Group (2:0) - Gray cell output (only G needed for carry)

  // Carries into each bit position: c_in[i] is carry into bit i
  wire [4:0] c_in;

  // 1. Calculate propagate and generate signals for each bit
  assign p = a ^ b;
  assign g = a & b;

  // 2. Calculate carries using Han-Carlson prefix tree
  // c_in[0] is the external carry-in, assumed 0 for simple addition
  assign c_in[0] = 1'b0;

  // Level 1 (distance 1) Black Cells
  // (G[1:0], P[1:0]) from (g[1], p[1]) and (g[0], p[0])
  assign G_1_0 = g[1] | (p[1] & g[0]);
  assign P_1_0 = p[1] & p[0];

  // (G[3:2], P[3:2]) from (g[3], p[3]) and (g[2], p[2])
  assign G_1_2 = g[3] | (p[3] & g[2]);
  assign P_1_2 = p[3] & p[2];

  // Level 2 (distance 2)
  // (G[3:0], P[3:0]) from (G[3:2], P[3:2]) and (G[1:0], P[1:0]) - Black Cell
  assign G_2_0 = G_1_2 | (P_1_2 & G_1_0);
  assign P_2_0 = P_1_2 & P_1_0; // P_2_0 is P[3:0], not explicitly used for carries here

  // (G[2:0]) from (g[2], p[2]) and (G[1:0], P[1:0]) - Gray Cell (only G needed)
  assign G_2_1 = g[2] | (p[2] & G_1_0);

  // Derive carries c_in[1]..c_in[4] from prefix tree outputs and c_in[0]
  // c_in[i+1] = G[i:0] | (P[i:0] & c_in[0])
  // Since c_in[0] = 0, c_in[i+1] = G[i:0]
  // c_in[1] = G[0:0] = g[0]
  // c_in[2] = G[1:0] = G_1_0
  // c_in[3] = G[2:0] = G_2_1
  // c_in[4] = G[3:0] = G_2_0

  assign c_in[1] = g[0];
  assign c_in[2] = G_1_0;
  assign c_in[3] = G_2_1;
  assign c_in[4] = G_2_0;

  // 3. Calculate sum bits
  // sum[i] = p[i] ^ c_in[i]
  assign sum[0] = p[0] ^ c_in[0]; // s0 = p0 ^ 0 = p0
  assign sum[1] = p[1] ^ c_in[1];
  assign sum[2] = p[2] ^ c_in[2];
  assign sum[3] = p[3] ^ c_in[3];

  // 4. Assign carry-out to sum[4]
  // sum[4] is the carry-out of the adder, which is c_in[4]
  assign sum[4] = c_in[4];

endmodule