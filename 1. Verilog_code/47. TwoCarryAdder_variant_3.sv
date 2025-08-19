//SystemVerilog
// SystemVerilog
module carry_select_adder_8bit (
  input [7:0] a,
  input [7:0] b,
  input       c_in,
  output [7:0] sum,
  output      carry
);

  // Brent-Kung adder implementation (8-bit)

  // Step 1: Generate (g) and Propagate (p) signals
  wire [7:0] bk_p; // Propagate: a[i] ^ b[i]
  wire [7:0] bk_g; // Generate: a[i] & b[i]

  assign bk_p = a ^ b;
  assign bk_g = a & b;

  // Step 2: Prefix network (G and P terms)
  // G_i_j, P_i_j cover bits j down to i
  // Black cell: (G_k:i, P_k:i) = (G_k:j+1 | (P_k:j+1 & G_j:i), P_k:j+1 & P_j:i)
  // Grey cell: (G_k:i, P_k:i) = (G_k:j+1 | (P_k:j+1 & G_j:i), P_k:j+1 & P_j:i) - same logic, different connections

  // Level 1 (span 2)
  wire G1_0, P1_0; // bits 1:0
  wire G1_2, P1_2; // bits 3:2
  wire G1_4, P1_4; // bits 5:4
  wire G1_6, P1_6; // bits 7:6

  assign G1_0 = bk_g[1] | (bk_p[1] & bk_g[0]);
  assign P1_0 = bk_p[1] & bk_p[0];

  assign G1_2 = bk_g[3] | (bk_p[3] & bk_g[2]);
  assign P1_2 = bk_p[3] & bk_p[2];

  assign G1_4 = bk_g[5] | (bk_p[5] & bk_g[4]);
  assign P1_4 = bk_p[5] & bk_p[4];

  assign G1_6 = bk_g[7] | (bk_p[7] & bk_g[6]);
  assign P1_6 = bk_p[7] & bk_p[6];

  // Level 2 (span 4)
  wire G2_0, P2_0; // bits 3:0
  wire G2_4, P2_4; // bits 7:4

  assign G2_0 = G1_2 | (P1_2 & G1_0);
  assign P2_0 = P1_2 & P1_0;

  assign G2_4 = G1_6 | (P1_6 & G1_4);
  assign P2_4 = P1_6 & P1_4;

  // Level 3 (span 8)
  wire G3_0, P3_0; // bits 7:0

  assign G3_0 = G2_4 | (P2_4 & G2_0);
  assign P3_0 = P2_4 & P2_0;

  // Step 3: Calculate carries C[1]...C[8]
  // C[i] is the carry into bit i
  wire [8:0] bk_c;

  assign bk_c[0] = c_in;
  assign bk_c[1] = bk_g[0] | (bk_p[0] & bk_c[0]);
  assign bk_c[2] = G1_0 | (P1_0 & bk_c[0]);
  assign bk_c[3] = bk_g[2] | (bk_p[2] & bk_c[2]);
  assign bk_c[4] = G2_0 | (P2_0 & bk_c[0]);
  assign bk_c[5] = bk_g[4] | (bk_p[4] & bk_c[4]);
  assign bk_c[6] = G1_4 | (P1_4 & bk_c[4]);
  assign bk_c[7] = bk_g[6] | (bk_p[6] & bk_c[6]);
  assign bk_c[8] = G3_0 | (P3_0 & bk_c[0]); // Carry out of bit 7

  // Step 4: Calculate sum
  assign sum = bk_p ^ bk_c[7:0];

  // Final carry out
  assign carry = bk_c[8];

endmodule