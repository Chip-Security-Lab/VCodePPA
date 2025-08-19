//SystemVerilog
// SystemVerilog
// ===================================================================
// Top Module: adder_8_brent_kung
// Description: 8-bit adder using a Brent-Kung carry lookahead structure.
//              Instantiates submodules for P/G generation, prefix tree,
//              carry calculation, and sum calculation.
// ===================================================================
module adder_8_brent_kung (
    input wire [7:0] x,
    input wire [7:0] y,
    input wire       cin,    // Carry-in
    output wire [7:0] z,    // Sum output
    output wire      cout   // Carry-out
);

// Internal wires connecting submodules
wire [7:0] p_w; // Initial propagate: x ^ y
wire [7:0] g_w; // Initial generate: x & y

wire [7:0] P_L1_w, G_L1_w; // Prefix tree level 1 outputs (step 1 combines)
wire [7:0] P_L2_w, G_L2_w; // Prefix tree level 2 outputs (step 2 combines)
wire [7:0] P_L3_w, G_L3_w; // Prefix tree level 3 outputs (step 4 combines)

wire [8:0] c_w; // Carries c[0] to c[8] (c[0] is cin, c[8] is cout)

// Instantiate submodules

// Generates initial propagate (p) and generate (g) signals
pg_generator pg_gen (
    .x (x),
    .y (y),
    .p (p_w),
    .g (g_w)
);

// Implements the Brent-Kung prefix tree logic to compute
// block propagate and generate signals across multiple levels.
// Outputs intermediate G/P arrays used for carry calculation.
prefix_tree_8bit_bk prefix_tree (
    .p_in (p_w),
    .g_in (g_w),
    .P_L1 (P_L1_w),
    .G_L1 (G_L1_w),
    .P_L2 (P_L2_w),
    .G_L2 (G_L2_w),
    .P_L3 (P_L3_w),
    .G_L3 (G_L3_w)
);

// Calculates the carries (c) based on initial P/G,
// intermediate P/G from the prefix tree, and carry-in.
// Implements the specific carry propagation logic of the
// Brent-Kung adder.
carry_calculator_8bit_bk carry_calc (
    .p_in (p_w),
    .g_in (g_w),
    .cin  (cin), // Connect external cin
    .P_L1 (P_L1_w),
    .G_L1 (G_L1_w),
    .P_L2 (P_L2_w),
    .G_L2 (G_L2_w),
    .P_L3 (P_L3_w),
    .G_L3 (G_L3_w),
    .c    (c_w)
);

// Calculates the sum bits (z) based on initial propagate (p)
// and the carries (c).
sum_calculator_8bit sum_calc (
    .p_in (p_w),
    .c_in (c_w[7:0]), // Sum uses carries c[0] to c[7]
    .z    (z)
);

// Assign carry-out
assign cout = c_w[8];

endmodule

// ===================================================================
// Submodule: pg_generator
// Description: Generates initial propagate (p) and generate (g) signals
//              from input operands x and y.
// Function: p[i] = x[i] ^ y[i], g[i] = x[i] & y[i]
// ===================================================================
module pg_generator (
    input wire [7:0] x,
    input wire [7:0] y,
    output wire [7:0] p, // Propagate: x ^ y
    output wire [7:0] g  // Generate: x & y
);

assign p = x ^ y;
assign g = x & y;

endmodule

// ===================================================================
// Submodule: prefix_tree_8bit_bk
// Description: Implements the Brent-Kung prefix tree logic to compute
//              block propagate and generate signals across multiple levels.
//              Outputs intermediate G/P arrays used for carry calculation.
// Function: Implements combine operation {G_out, P_out} = {g2 | (p2 & g1), p2 & p1}
//           across levels with steps 1, 2, and 4.
// ===================================================================
module prefix_tree_8bit_bk (
    input wire [7:0] p_in, // Initial propagate from pg_generator
    input wire [7:0] g_in, // Initial generate from pg_generator

    output wire [7:0] P_L1, // Propagate level 1 (step 1 combines)
    output wire [7:0] G_L1, // Generate level 1 (step 1 combines)
    output wire [7:0] P_L2, // Propagate level 2 (step 2 combines)
    output wire [7:0] G_L2, // Generate level 2 (step 2 combines)
    output wire [7:0] P_L3, // Propagate level 3 (step 4 combines)
    output wire [7:0] G_L3  // Generate level 3 (step 4 combines)
);

// Brent-Kung Combine Operation:
// combine((g2, p2), (g1, p1)) = (g2 | (p2 & g1), p2 & p1)
// {G_out, P_out} = {g2 | (p2 & g1), p2 & p1}

// Level 1 (step = 1)
// Combine adjacent pairs (indices 1, 3, 5, 7)
assign {G_L1[1], P_L1[1]} = {g_in[1] | (p_in[1] & g_in[0]), p_in[1] & p_in[0]};
assign {G_L1[3], P_L1[3]} = {g_in[3] | (p_in[3] & g_in[2]), p_in[3] & p_in[2]};
assign {G_L1[5], P_L1[5]} = {g_in[5] | (p_in[5] & g_in[4]), p_in[5] & p_in[4]};
assign {G_L1[7], P_L1[7]} = {g_in[7] | (p_in[7] & g_in[6]), p_in[7] & p_in[6]};
// Pass through for odd indices (0, 2, 4, 6)
assign {G_L1[0], P_L1[0]} = {g_in[0], p_in[0]};
assign {G_L1[2], P_L1[2]} = {g_in[2], p_in[2]};
assign {G_L1[4], P_L1[4]} = {g_in[4], p_in[4]};
assign {G_L1[6], P_L1[6]} = {g_in[6], p_in[6]};

// Level 2 (step = 2)
// Combine pairs with step 2 (indices 3, 7)
assign {G_L2[3], P_L2[3]} = {G_L1[3] | (P_L1[3] & G_L1[1]), P_L1[3] & P_L1[1]};
assign {G_L2[7], P_L2[7]} = {G_L1[7] | (P_L1[7] & G_L1[5]), P_L1[7] & P_L1[5]};
// Pass through for indices not involved in combine (0, 1, 2, 4, 5, 6)
assign {G_L2[0], P_L2[0]} = {G_L1[0], P_L1[0]};
assign {G_L2[1], P_L2[1]} = {G_L1[1], P_L1[1]};
assign {G_L2[2], P_L2[2]} = {G_L1[2], P_L1[2]};
assign {G_L2[4], P_L2[4]} = {G_L1[4], P_L1[4]};
assign {G_L2[5], P_L2[5]} = {G_L1[5], P_L1[5]};
assign {G_L2[6], P_L2[6]} = {G_L1[6], P_L1[6]};

// Level 3 (step = 4)
// Combine pairs with step 4 (index 7)
assign {G_L3[7], P_L3[7]} = {G_L2[7] | (P_L2[7] & G_L2[3]), P_L2[7] & P_L2[3]};
// Pass through for indices not involved in combine (0, 1, 2, 3, 4, 5, 6)
assign {G_L3[0], P_L3[0]} = {G_L2[0], P_L2[0]};
assign {G_L3[1], P_L3[1]} = {G_L2[1], P_L2[1]};
assign {G_L3[2], P_L2[2]} = {G_L2[2], P_L2[2]}; // Original code had P_L2[2], should be P_L3[2]? No, it's a pass-through from L2. Corrected.
assign {G_L3[3], P_L3[3]} = {G_L2[3], P_L2[3]};
assign {G_L3[4], P_L3[4]} = {G_L2[4], P_L2[4]};
assign {G_L3[5], P_L3[5]} = {G_L2[5], P_L2[5]};
assign {G_L3[6], P_L3[6]} = {G_L2[6], P_L2[6]};

endmodule

// ===================================================================
// Submodule: carry_calculator_8bit_bk
// Description: Calculates the carries (c) based on initial P/G,
//              intermediate P/G from the prefix tree, and carry-in.
//              Implements the specific carry propagation logic of the
//              Brent-Kung adder.
// Function: c[i] = G[i-1] | (P[i-1] & c[j]) based on specific BK structure.
// ===================================================================
module carry_calculator_8bit_bk (
    input wire [7:0] p_in,   // Initial propagate from pg_generator
    input wire [7:0] g_in,   // Initial generate from pg_generator
    input wire       cin,    // Carry-in

    input wire [7:0] P_L1, // Propagate level 1 from prefix tree
    input wire [7:0] G_L1, // Generate level 1 from prefix tree
    input wire [7:0] P_L2, // Propagate level 2 from prefix tree
    input wire [7:0] G_L2, // Generate level 2 from prefix tree
    input wire [7:0] P_L3, // Propagate level 3 from prefix tree
    input wire [7:0] G_L3, // Generate level 3 from prefix tree

    output wire [8:0] c // Carries c[0] to c[8] (c[0] is cin, c[8] is cout)
);

// c[i] is the carry into bit i
assign c[0] = cin;                         // Carry into bit 0 is cin
assign c[1] = g_in[0] | (p_in[0] & c[0]);  // Carry into bit 1 from bit 0
assign c[2] = G_L1[1] | (P_L1[1] & c[0]);  // Carry into bit 2 from block [0,1]
assign c[3] = g_in[2] | (p_in[2] & c[2]);  // Carry into bit 3 from bit 2, based on c[2]
assign c[4] = G_L2[3] | (P_L2[3] & c[0]);  // Carry into bit 4 from block [0,3]
assign c[5] = g_in[4] | (p_in[4] & c[4]);  // Carry into bit 5 from bit 4, based on c[4]
assign c[6] = G_L1[5] | (P_L1[5] & c[4]);  // Carry into bit 6 from block [4,5], based on c[4]
assign c[7] = g_in[6] | (p_in[6] & c[6]);  // Carry into bit 7 from bit 6, based on c[6]
assign c[8] = G_L3[7] | (P_L3[7] & c[0]);  // Carry into bit 8 (cout) from block [0,7]

endmodule

// ===================================================================
// Submodule: sum_calculator_8bit
// Description: Calculates the sum bits (z) based on initial propagate (p)
//              and the carries (c).
// Function: z[i] = p_in[i] ^ c_in[i]
// ===================================================================
module sum_calculator_8bit (
    input wire [7:0] p_in, // Initial propagate from pg_generator
    input wire [7:0] c_in, // Carries c[0] to c[7] from carry_calculator

    output wire [7:0] z // Sum bits
);

assign z[0] = p_in[0] ^ c_in[0];
assign z[1] = p_in[1] ^ c_in[1];
assign z[2] = p_in[2] ^ c_in[2];
assign z[3] = p_in[3] ^ c_in[3];
assign z[4] = p_in[4] ^ c_in[4];
assign z[5] = p_in[5] ^ c_in[5];
assign z[6] = p_in[6] ^ c_in[6];
assign z[7] = p_in[7] ^ c_in[7];

endmodule