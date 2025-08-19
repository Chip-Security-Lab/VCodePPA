//SystemVerilog
// SystemVerilog

//----------------------------------------------------------------------------
// Top level module for 8-bit Brent-Kung Adder
// Orchestrates the sub-modules for initial P/G, prefix tree, carry, and sum calculation.
//----------------------------------------------------------------------------
module adder_8_bk (
  input wire [7:0] a,
  input wire [7:0] b,
  output wire [7:0] sum,
  output wire      cout
);

  // Internal signals
  wire [7:0] p; // Propagate: a_i ^ b_i
  wire [7:0] g; // Generate: a_i & b_i

  // Signals from prefix tree module
  wire [7:0] P1_tree, G1_tree; // Level 1 prefix P/G (indices 1,3,5,7)
  wire [7:0] P2_tree, G2_tree; // Level 2 prefix P/G (indices 3,7)
  wire [7:0] P3_tree, G3_tree; // Level 3 prefix P/G (index 7)

  // Signals from carry calculator module
  wire [8:0] c; // Carries (c[i] is carry into bit i)

  // Initial propagate and generate calculation
  // This is a simple bitwise operation, kept in the top module.
  assign p = a ^ b;
  assign g = a & b;

  // Instantiate the prefix tree module
  // Computes the intermediate prefix P and G signals based on initial p and g.
  bk_prefix_tree bk_tree_inst (
    .p_in   (p),
    .g_in   (g),
    .P1_out (P1_tree),
    .G1_out (G1_tree),
    .P2_out (P2_tree),
    .G2_out (G2_tree),
    .P3_out (P3_tree),
    .G3_out (G3_tree)
  );

  // Instantiate the carry calculator module
  // Computes all carries based on initial p/g, prefix P/G, and input carry (cin).
  // Original code assumes cin = 0, so we tie cin to 0.
  carry_calculator carry_calc_inst (
    .p_in    (p),
    .g_in    (g),
    .P1_in   (P1_tree),
    .G1_in   (G1_tree),
    .P2_in   (P2_tree),
    .G2_in   (G2_tree),
    .P3_in   (P3_tree),
    .G3_in   (G3_tree),
    .cin     (1'b0), // Tie cin to 0 as per original code
    .c_out   (c)
  );

  // Instantiate the sum calculator module
  // Computes the sum bits based on initial propagate and carries.
  sum_calculator sum_calc_inst (
    .p_in    (p),
    .c_in    (c[7:0]), // sum[i] = p[i] ^ c[i]
    .sum_out (sum)
  );

  // Assign the final carry out
  assign cout = c[8];

endmodule

//----------------------------------------------------------------------------
// Sub-module: bk_prefix_tree
// Calculates the prefix P and G signals required for the Brent-Kung carry logic.
// Implements the tree structure combining P/G pairs at different levels.
//----------------------------------------------------------------------------
module bk_prefix_tree (
  input wire [7:0] p_in,
  input wire [7:0] g_in,
  output wire [7:0] P1_out, // P for blocks of size 2
  output wire [7:0] G1_out, // G for blocks of size 2
  output wire [7:0] P2_out, // P for blocks of size 4
  output wire [7:0] G2_out, // G for blocks of size 4
  output wire [7:0] P3_out, // P for blocks of size 8
  output wire [7:0] G3_out  // G for blocks of size 8
);

  // Internal wires for P and G at different levels.
  // Only specific indices are valid outputs from the tree nodes.
  wire [7:0] P1, G1; // Valid at indices 1, 3, 5, 7
  wire [7:0] P2, G2; // Valid at indices 3, 7
  wire [7:0] P3, G3; // Valid at index 7

  // Level 1: Combine adjacent pairs (i=1, 3, 5, 7)
  // (P_out, G_out) = (P_right & P_left, G_right | (P_right & G_left))
  // P1[i], G1[i] = BK_cell((p_in[i], g_in[i]), (p_in[i-1], g_in[i-1]))
  assign P1[1] = p_in[1] & p_in[0];
  assign G1[1] = g_in[1] | (p_in[1] & g_in[0]);

  assign P1[3] = p_in[3] & p_in[2];
  assign G1[3] = g_in[3] | (p_in[3] & g_in[2]);

  assign P1[5] = p_in[5] & p_in[4];
  assign G1[5] = g_in[5] | (p_in[5] & g_in[4]);

  assign P1[7] = p_in[7] & p_in[6];
  assign G1[7] = g_in[7] | (p_in[7] & g_in[6]);

  // Level 2: Combine groups of 4 (i=3, 7)
  // P2[i], G2[i] = BK_cell((P1[i], G1[i]), (P1[i-2], G1[i-2]))
  assign P2[3] = P1[3] & P1[1];
  assign G2[3] = G1[3] | (P1[3] & G1[1]);

  assign P2[7] = P1[7] & P1[5];
  assign G2[7] = G1[7] | (P1[7] & G1[5]);

  // Level 3: Combine groups of 8 (i=7)
  // P3[i], G3[i] = BK_cell((P2[i], G2[i]), (P2[i-4], G2[i-4]))
  assign P3[7] = P2[7] & P2[3];
  assign G3[7] = G2[7] | (P2[7] & G2[3]);

  // Output the calculated prefix signals.
  // Note: Only the indices calculated are meaningful.
  assign P1_out = P1;
  assign G1_out = G1;
  assign P2_out = P2;
  assign G2_out = G2;
  assign P3_out = P3;
  assign G3_out = G3;

endmodule

//----------------------------------------------------------------------------
// Sub-module: carry_calculator
// Calculates the carry-in for each bit position (c[1] through c[7])
// and the final carry-out (c[8]), based on initial p/g, prefix P/G, and cin.
// Implements the specific carry lookahead logic for the 8-bit BK adder.
//----------------------------------------------------------------------------
module carry_calculator (
  input wire [7:0] p_in,
  input wire [7:0] g_in,
  input wire [7:0] P1_in, // Prefix P level 1
  input wire [7:0] G1_in, // Prefix G level 1
  input wire [7:0] P2_in, // Prefix P level 2
  input wire [7:0] G2_in, // Prefix G level 2
  input wire [7:0] P3_in, // Prefix P level 3
  input wire [7:0] G3_in, // Prefix G level 3
  input wire      cin,   // Carry in for bit 0
  output wire [8:0] c_out  // Carries c[0]...c[8]
);

  // Internal wires for carries
  wire [8:0] c;

  // c[0] is the input carry
  assign c[0] = cin;

  // Calculate carries based on initial p/g and prefix P/G from the tree.
  // c[i] is carry into bit i.
  // c[i] = G_{i-1} (prefix generate up to bit i-1) OR
  // c[i] = g[i-1] | (p[i-1] & c[i-1]) (ripple like step) OR
  // c[i] = G_block | (P_block & c_into_block)
  assign c[1] = g_in[0];                  // Carry into bit 1 is generate from bit 0
  assign c[2] = G1_in[1];                 // Carry into bit 2 is G for block [1:0]
  assign c[3] = g_in[2] | (p_in[2] & c[2]);  // Carry into bit 3 uses g[2], p[2] and carry into bit 2
  assign c[4] = G2_in[3];                 // Carry into bit 4 is G for block [3:0]
  assign c[5] = g_in[4] | (p_in[4] & c[4]);  // Carry into bit 5 uses g[4], p[4] and carry into bit 4
  assign c[6] = G1_in[5] | (P1_in[5] & c[4]); // Carry into bit 6 is G for block [5:4] combined with carry into block [5:4] (which is c[4])
  assign c[7] = g_in[6] | (p_in[6] & c[6]);  // Carry into bit 7 uses g[6], p[6] and carry into bit 6
  assign c[8] = G3_in[7];                 // Carry out is G for block [7:0]

  // Output the calculated carries
  assign c_out = c;

endmodule

//----------------------------------------------------------------------------
// Sub-module: sum_calculator
// Calculates the sum bits based on the initial propagate signals and the carries.
// sum_i = p_i ^ c_i
//----------------------------------------------------------------------------
module sum_calculator (
  input wire [7:0] p_in, // Propagate signals
  input wire [7:0] c_in, // Carries c[0]...c[7]
  output wire [7:0] sum_out // Sum bits
);

  // Calculate sum bits
  assign sum_out[0] = p_in[0] ^ c_in[0];
  assign sum_out[1] = p_in[1] ^ c_in[1];
  assign sum_out[2] = p_in[2] ^ c_in[2];
  assign sum_out[3] = p_in[3] ^ c_in[3];
  assign sum_out[4] = p_in[4] ^ c_in[4];
  assign sum_out[5] = p_in[5] ^ c_in[5];
  assign sum_out[6] = p_in[6] ^ c_in[6];
  assign sum_out[7] = p_in[7] ^ c_in[7];

endmodule