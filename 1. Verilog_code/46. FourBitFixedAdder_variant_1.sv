//SystemVerilog
// N=4 Brent-Kung Adder
module adder_14 (
  input wire [3:0] a,
  input wire [3:0] b,
  output wire [4:0] sum
);

  // Bit-level generate and propagate (Level 0)
  wire [3:0] g; // g[i] = a[i] & b[i]
  wire [3:0] p; // p[i] = a[i] ^ b[i]

  // Prefix computation levels (Black cells)
  // Level 1 (Pairs)
  wire [1:0] g_lvl1; // g_lvl1[0]=G[1:0], g_lvl1[1]=G[3:2]
  wire [1:0] p_lvl1; // p_lvl1[0]=P[1:0], p_lvl1[1]=P[3:2]
  // Level 2 (Groups of 4)
  wire        g_lvl2; // g_lvl2=G[3:0]
  wire        p_lvl2; // p_lvl2=P[3:0]

  // Intermediate G/P for carries (Gray cells / pass-throughs and combinations)
  wire [2:0] g_gray; // g_gray[0]=G[0:0], g_gray[1]=G[2:2], g_gray[2]=G[2:0]
  wire [1:0] p_gray; // p_gray[0]=P[0:0], p_gray[1]=P[2:2]

  // Carries (c[i] is the carry into bit i)
  wire [4:0] c;

  // Assume no external carry-in for the least significant bit
  assign c[0] = 1'b0; // Cin is 0

  // 1. Pre-computation (Level 0 G/P)
  assign g = a & b;
  assign p = a ^ b;

  // 2. Prefix Computation (Brent-Kung Structure)

  // Level 1 (Pairs) - Black cells
  assign g_lvl1[0] = g[1] | (p[1] & g[0]); // G[1:0]
  assign p_lvl1[0] = p[1] & p[0];             // P[1:0]

  assign g_lvl1[1] = g[3] | (p[3] & g[2]); // G[3:2]
  assign p_lvl1[1] = p[3] & p[2];             // P[3:2]

  // Level 2 (Groups of 4) - Black cell
  assign g_lvl2 = g_lvl1[1] | (p_lvl1[1] & g_lvl1[0]); // G[3:0]
  assign p_lvl2 = p_lvl1[1] & p_lvl1[0];             // P[3:0]

  // Intermediate G/P for carry calculation (Gray cells / pass-throughs and combinations)
  // Pass-throughs from Level 0
  assign g_gray[0] = g[0]; // G[0:0]
  assign p_gray[0] = p[0]; // P[0:0]

  assign g_gray[1] = g[2]; // G[2:2]
  assign p_gray[1] = p[2]; // P[2:2]

  // Combination for G[2:0]
  assign g_gray[2] = g_gray[1] | (p_gray[1] & g_lvl1[0]); // G[2:0] = G[2:2] | (P[2:2] & G[1:0])

  // 3. Carry Calculation (using prefix G/P)
  // c[i] = G[i-1:0] | (P[i-1:0] & c[0])
  // Since c[0] = 0, c[i] = G[i-1:0]

  assign c[1] = g_gray[0]; // G[0:0]
  assign c[2] = g_lvl1[0];       // G[1:0]
  assign c[3] = g_gray[2]; // G[2:0]
  assign c[4] = g_lvl2;       // G[3:0] (Carry out)

  // 4. Sum Calculation
  assign sum[0] = p[0] ^ c[0]; // p[0] ^ 0
  assign sum[1] = p[1] ^ c[1];
  assign sum[2] = p[2] ^ c[2];
  assign sum[3] = p[3] ^ c[3];
  assign sum[4] = c[4];          // Carry out is the MSB of sum

endmodule