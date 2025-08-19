//SystemVerilog
// SystemVerilog
// Brent-Kung Adder (Hierarchical 8-bit)
// Top level module instantiating sub-modules

module adder_bk_hierarchical #(
    parameter WIDTH = 8
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire             cin,
    output wire [WIDTH-1:0] sum,
    output wire            cout
);

    // Intermediate signals
    wire [WIDTH-1:0] p_l0; // Propagate signals at level 0
    wire [WIDTH-1:0] g_l0; // Generate signals at level 0

    // Group Propagate and Generate signals from the generate tree
    // Indices correspond to the highest bit in the group, similar to original code
    wire [WIDTH-1:0] p_group;
    wire [WIDTH-1:0] g_group;

    // Carry signals (c[i] is the carry *into* bit i)
    // c[0] = cin, c[WIDTH] = cout
    wire [WIDTH:0]   c;

    // Instantiate Pre-processing module (Level 0 P and G)
    bk_pre_processing #(
        .WIDTH(WIDTH)
    ) pre_proc_inst (
        .a(a),
        .b(b),
        .p(p_l0),
        .g(g_l0)
    );

    // Instantiate Generate Tree module (Group P and G)
    bk_generate_tree #(
        .WIDTH(WIDTH)
    ) gen_tree_inst (
        .p_l0(p_l0),
        .g_l0(g_l0),
        .p_group(p_group),
        .g_group(g_group)
    );

    // Instantiate Carry Tree module (Carries)
    bk_carry_tree #(
        .WIDTH(WIDTH)
    ) carry_tree_inst (
        .p_l0(p_l0),
        .g_l0(g_l0),
        .p_group(p_group),
        .g_group(g_group),
        .cin(cin),
        .c(c)
    );

    // Instantiate Post-processing module (Sum)
    bk_post_processing #(
        .WIDTH(WIDTH)
    ) post_proc_inst (
        .p(p_l0),
        .c_in(c[WIDTH-1:0]), // Connect carries c[0] through c[WIDTH-1]
        .sum(sum)
    );

    // Connect cout
    assign cout = c[WIDTH];

endmodule

// Submodule: bk_pre_processing
// Calculates bit-level propagate (P) and generate (G) signals.
module bk_pre_processing #(
    parameter WIDTH = 8
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] p, // Propagate: a ^ b
    output wire [WIDTH-1:0] g  // Generate: a & b
);

    assign p = a ^ b;
    assign g = a & b;

endmodule

// Submodule: bk_black_cell
// Standard Black Cell in a carry-tree adder.
// Calculates combined P and G for two adjacent groups/bits.
module bk_black_cell (
    input wire p_l, // Propagate from left (lower bits)
    input wire g_l, // Generate from left (lower bits)
    input wire p_r, // Propagate from right (higher bits)
    input wire g_r, // Generate from right (higher bits)
    output wire p_out, // Combined Propagate
    output wire g_out  // Combined Generate
);

    assign p_out = p_r & p_l;
    assign g_out = g_r | (p_r & g_l);

endmodule

// Submodule: bk_gray_cell
// Standard Gray Cell in a carry-tree adder.
// Calculates a carry based on group P/G and a previous carry.
module bk_gray_cell (
    input wire p_in, // Propagate input (can be bit-level or group)
    input wire g_in, // Generate input (can be bit-level or group)
    input wire c_in, // Carry input
    output wire c_out // Carry output
);

    assign c_out = g_in | (p_in & c_in);

endmodule

// Submodule: bk_generate_tree
// Builds the tree structure for calculating group P and G signals.
// For 8-bit, this involves levels for 2-bit, 4-bit, and 8-bit groups.
module bk_generate_tree #(
    parameter WIDTH = 8
) (
    input wire [WIDTH-1:0] p_l0,    // Level 0 Propagate
    input wire [WIDTH-1:0] g_l0,    // Level 0 Generate
    output wire [WIDTH-1:0] p_group, // Group Propagate (indices used: 1,3,5,7 for L1; 3,7 for L2; 7 for L3)
    output wire [WIDTH-1:0] g_group  // Group Generate (indices used: 1,3,5,7 for L1; 3,7 for L2; 7 for L3)
);

    // Internal wires for clarity, though output indices match original logic
    wire [WIDTH-1:0] p_l1_int, g_l1_int; // Level 1 (2-bit groups)
    wire [WIDTH-1:0] p_l2_int, g_l2_int; // Level 2 (4-bit groups)
    wire [WIDTH-1:0] p_l3_int, g_l3_int; // Level 3 (8-bit group)

    // Level 1 (2-bit groups: 1:0, 3:2, 5:4, 7:6)
    bk_black_cell bc_l1_0to1 (.p_l(p_l0[0]), .g_l(g_l0[0]), .p_r(p_l0[1]), .g_r(g_l0[1]), .p_out(p_l1_int[1]), .g_out(g_l1_int[1]));
    bk_black_cell bc_l1_2to3 (.p_l(p_l0[2]), .g_l(g_l0[2]), .p_r(p_l0[3]), .g_r(g_l0[3]), .p_out(p_l1_int[3]), .g_out(g_l1_int[3]));
    bk_black_cell bc_l1_4to5 (.p_l(p_l0[4]), .g_l(g_l0[4]), .p_r(p_l0[5]), .g_r(g_l0[5]), .p_out(p_l1_int[5]), .g_out(g_l1_int[5]));
    bk_black_cell bc_l1_6to7 (.p_l(p_l0[6]), .g_l(g_l0[6]), .p_r(p_l0[7]), .g_r(g_l0[7]), .p_out(p_l1_int[7]), .g_out(g_l1_int[7]));

    // Level 2 (4-bit groups: 3:0, 7:4)
    bk_black_cell bc_l2_0to3 (.p_l(p_l1_int[1]), .g_l(g_l1_int[1]), .p_r(p_l1_int[3]), .g_r(g_l1_int[3]), .p_out(p_l2_int[3]), .g_out(g_l2_int[3]));
    bk_black_cell bc_l2_4to7 (.p_l(p_l1_int[5]), .g_l(g_l1_int[5]), .p_r(p_l1_int[7]), .g_r(g_l1_int[7]), .p_out(p_l2_int[7]), .g_out(g_l2_int[7]));

    // Level 3 (8-bit group: 7:0)
    bk_black_cell bc_l3_0to7 (.p_l(p_l2_int[3]), .g_l(g_l2_int[3]), .p_r(p_l2_int[7]), .g_r(g_l2_int[7]), .p_out(p_l3_int[7]), .g_out(g_l3_int[7]));

    // Assign outputs - match indices used in original code for carry calculation
    assign p_group[1] = p_l1_int[1];
    assign g_group[1] = g_l1_int[1];
    assign p_group[3] = p_l2_int[3]; // Note: L2 group 3:0 stored at index 3
    assign g_group[3] = g_l2_int[3]; // Note: L2 group 3:0 stored at index 3
    assign p_group[5] = p_l1_int[5];
    assign g_group[5] = g_l1_int[5];
    assign p_group[7] = p_l3_int[7]; // Note: L3 group 7:0 stored at index 7
    assign g_group[7] = g_l3_int[7]; // Note: L3 group 7:0 stored at index 7

    // Other indices are unused for P_group/G_group in the original carry calculation structure
    // Drive them to 0 or X to avoid floating wires if needed, but for synthesis
    // connecting only used indices is sufficient. Let's drive unused to 0.
    assign p_group[0] = 1'b0; assign g_group[0] = 1'b0;
    assign p_group[2] = 1'b0; assign g_group[2] = 1'b0;
    assign p_group[4] = 1'b0; assign g_group[4] = 1'b0;
    assign p_group[6] = 1'b0; assign g_group[6] = 1'b0;

endmodule

// Submodule: bk_carry_tree
// Builds the tree structure for calculating carries using bit-level and group P/G signals.
module bk_carry_tree #(
    parameter WIDTH = 8
) (
    input wire [WIDTH-1:0] p_l0,    // Level 0 Propagate
    input wire [WIDTH-1:0] g_l0,    // Level 0 Generate
    input wire [WIDTH-1:0] p_group, // Group Propagate (from bk_generate_tree)
    input wire [WIDTH-1:0] g_group, // Group Generate (from bk_generate_tree)
    input wire             cin,     // Carry input to bit 0
    output wire [WIDTH:0]  c        // Carries c[0] to c[WIDTH] (cout)
);

    // Assign the input carry
    assign c[0] = cin;

    // Calculate carries using Gray Cells based on the Brent-Kung structure
    // c[i] = G_i-1:j | (P_i-1:j & C_j) where j is the start of the group contributing to c[i]
    // The original code's carry calculations map directly to Gray cells:
    // c[1] = g_l0[0] | (p_l0[0] & c[0])             -> uses P_0:0, G_0:0 and C_0
    // c[2] = g_group[1] | (p_group[1] & c[0])       -> uses P_1:0, G_1:0 and C_0
    // c[3] = g_l0[2] | (p_l0[2] & c[2])             -> uses P_2:2, G_2:2 and C_2
    // c[4] = g_group[3] | (p_group[3] & c[0])       -> uses P_3:0, G_3:0 and C_0
    // c[5] = g_l0[4] | (p_l0[4] & c[4])             -> uses P_4:4, G_4:4 and C_4
    // c[6] = g_group[5] | (p_group[5] & c[4])       -> uses P_5:4, G_5:4 and C_4
    // c[7] = g_l0[6] | (p_l0[6] & c[6])             -> uses P_6:6, G_6:6 and C_6
    // c[8] = g_group[7] | (p_group[7] & c[0])       -> uses P_7:0, G_7:0 and C_0 (this is cout)

    bk_gray_cell gc_c1 (.p_in(p_l0[0]),    .g_in(g_l0[0]),    .c_in(c[0]), .c_out(c[1]));
    bk_gray_cell gc_c2 (.p_in(p_group[1]), .g_in(g_group[1]), .c_in(c[0]), .c_out(c[2]));
    bk_gray_cell gc_c3 (.p_in(p_l0[2]),    .g_in(g_l0[2]),    .c_in(c[2]), .c_out(c[3]));
    bk_gray_cell gc_c4 (.p_in(p_group[3]), .g_in(g_group[3]), .c_in(c[0]), .c_out(c[4]));
    bk_gray_cell gc_c5 (.p_in(p_l0[4]),    .g_in(g_l0[4]),    .c_in(c[4]), .c_out(c[5]));
    bk_gray_cell gc_c6 (.p_in(p_group[5]), .g_in(g_group[5]), .c_in(c[4]), .c_out(c[6]));
    bk_gray_cell gc_c7 (.p_in(p_l0[6]),    .g_in(g_l0[6]),    .c_in(c[6]), .c_out(c[7]));
    bk_gray_cell gc_c8 (.p_in(p_group[7]), .g_in(g_group[7]), .c_in(c[0]), .c_out(c[8])); // c[8] is cout

endmodule

// Submodule: bk_post_processing
// Calculates the final sum bits using bit-level propagate and carry-in signals.
module bk_post_processing #(
    parameter WIDTH = 8
) (
    input wire [WIDTH-1:0] p,    // Bit-level Propagate (a ^ b)
    input wire [WIDTH-1:0] c_in, // Carry into each bit (c[0] to c[WIDTH-1])
    output wire [WIDTH-1:0] sum  // Sum output
);

    // sum[i] = p[i] ^ c[i]
    assign sum = p ^ c_in;

endmodule