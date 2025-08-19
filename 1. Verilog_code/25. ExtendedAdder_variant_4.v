// Hierarchical 4-bit Kogge-Stone Adder
// Top-level module orchestrating the adder components
module Adder_3 (
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum // 4-bit sum + carry-out
);

// Internal wires to connect submodules
wire [4:0] initial_p;
wire [4:0] initial_g;
wire [4:0] final_g_prefix; // Corresponds to g_stage3_out from the Kogge-Stone prefix module

// Instantiate Input Extension and Initial GP Calculation module
// Calculates initial generate (g) and propagate (p) signals from inputs A and B
input_gp_calc u_input_gp_calc (
    .A(A),
    .B(B),
    .p(initial_p),
    .g(initial_g)
);

// Instantiate Kogge-Stone Prefix Computation module
// Computes the prefix generate signals required for carries
kogge_stone_prefix u_kogge_stone_prefix (
    .p_in(initial_p),
    .g_in(initial_g),
    .g_prefix(final_g_prefix)
);

// Instantiate Sum Calculation module
// Calculates the final sum bits based on initial propagate and prefix generate signals (carries)
sum_calculator u_sum_calculator (
    .p_in(initial_p),
    .g_prefix_in(final_g_prefix),
    .sum(sum)
);

endmodule

// This module calculates initial Generate (g) and Propagate (p) signals
// from the input operands A and B, extending them by one bit for carry logic.
module input_gp_calc (
    input [3:0] A,
    input [3:0] B,
    output [4:0] p, // Initial propagate signals (extended to 5 bits)
    output [4:0] g  // Initial generate signals (extended to 5 bits)
);

wire [4:0] a_ext;
wire [4:0] b_ext;

// Extend inputs to 5 bits by prepending a '0'
assign a_ext = {1'b0, A};
assign b_ext = {1'b0, B};

// Initial Generate (g) and Propagate (p) calculation for each bit position
// g[i] = a[i] AND b[i]
// p[i] = a[i] XOR b[i]
assign g = a_ext & b_ext;
assign p = a_ext ^ b_ext;

endmodule

// This module computes the prefix generate signals using a chained Kogge-Stone structure.
// It instantiates individual stage modules to perform the prefix calculations.
module kogge_stone_prefix (
    input [4:0] p_in, // Initial propagate signals (extended)
    input [4:0] g_in, // Initial generate signals (extended)
    output [4:0] g_prefix // Final prefix generate signals (used for carries)
);

// Intermediate GP signals between stages
wire [4:0] g_stage1_out;
wire [4:0] p_stage1_out;
wire [4:0] g_stage2_out;
wire [4:0] p_stage2_out;
wire [4:0] g_stage3_out; // Output of the final stage

// Instantiate Kogge-Stone Stage 1 (step = 1)
// Computes prefix generates/propagates with a step of 1
kogge_stone_stage1 u_stage1 (
    .p_in(p_in),
    .g_in(g_in),
    .p_out(p_stage1_out),
    .g_out(g_stage1_out)
);

// Instantiate Kogge-Stone Stage 2 (step = 2)
// Computes prefix generates/propagates with a step of 2
kogge_stone_stage2 u_stage2 (
    .p_in(p_stage1_out),
    .g_in(g_stage1_out),
    .p_out(p_stage2_out),
    .g_out(g_stage2_out)
);

// Instantiate Kogge-Stone Stage 3 (step = 4)
// Computes prefix generates/propagates with a step of 4
kogge_stone_stage3 u_stage3 (
    .p_in(p_stage2_out),
    .g_in(g_stage2_out),
    .p_out(p_stage3_out), // p_stage3_out is not used outside this module chain
    .g_out(g_stage3_out)
);

// The final prefix generate signals are the output of the last stage
assign g_prefix = g_stage3_out;

endmodule

// This module implements one stage of the Kogge-Stone prefix computation with step = 1.
// g_out[i] = g_in[i] | (p_in[i] & g_in[i-1])
// p_out[i] = p_in[i] & p_in[i-1]
// Boundary condition for i=0: g_out[0] = g_in[0], p_out[0] = p_in[0]
module kogge_stone_stage1 (
    input [4:0] p_in,
    input [4:0] g_in,
    output [4:0] p_out,
    output [4:0] g_out
);

    assign g_out[0] = g_in[0];
    assign p_out[0] = p_in[0];
    assign g_out[1] = g_in[1] | (p_in[1] & g_in[0]);
    assign p_out[1] = p_in[1] & p_in[0];
    assign g_out[2] = g_in[2] | (p_in[2] & g_in[1]);
    assign p_out[2] = p_in[2] & p_in[1];
    assign g_out[3] = g_in[3] | (p_in[3] & g_in[2]);
    assign p_out[3] = p_in[3] & p_in[2];
    assign g_out[4] = g_in[4] | (p_in[4] & g_in[3]);
    assign p_out[4] = p_in[4] & p_in[3];

endmodule

// This module implements one stage of the Kogge-Stone prefix computation with step = 2.
// g_out[i] = g_in[i] | (p_in[i] & g_in[i-2])
// p_out[i] = p_in[i] & p_in[i-2]
// Boundary conditions for i < 2: g_out[i] = g_in[i], p_out[i] = p_in[i]
module kogge_stone_stage2 (
    input [4:0] p_in,
    input [4:0] g_in,
    output [4:0] p_out,
    output [4:0] g_out
);

    assign g_out[0] = g_in[0];
    assign p_out[0] = p_in[0];
    assign g_out[1] = g_in[1];
    assign p_out[1] = p_in[1];
    assign g_out[2] = g_in[2] | (p_in[2] & g_in[0]); // Index 2-2 = 0
    assign p_out[2] = p_in[2] & p_in[0];
    assign g_out[3] = g_in[3] | (p_in[3] & g_in[1]); // Index 3-2 = 1
    assign p_out[3] = p_in[3] & p_in[1];
    assign g_out[4] = g_in[4] | (p_in[4] & g_in[2]); // Index 4-2 = 2
    assign p_out[4] = p_in[4] & p_in[2];

endmodule

// This module implements one stage of the Kogge-Stone prefix computation with step = 4.
// g_out[i] = g_in[i] | (p_in[i] & g_in[i-4])
// p_out[i] = p_in[i] & p_in[i-4]
// Boundary conditions for i < 4: g_out[i] = g_in[i], p_out[i] = p_in[i]
module kogge_stone_stage3 (
    input [4:0] p_in,
    input [4:0] g_in,
    output [4:0] p_out,
    output [4:0] g_out
);

    assign g_out[0] = g_in[0];
    assign p_out[0] = p_in[0];
    assign g_out[1] = g_in[1];
    assign p_out[1] = p_in[1];
    assign g_out[2] = g_in[2];
    assign p_out[2] = p_in[2];
    assign g_out[3] = g_in[3];
    assign p_out[3] = p_in[3];
    assign g_out[4] = g_in[4] | (p_in[4] & g_in[0]); // Index 4-4 = 0
    assign p_out[4] = p_in[4] & p_in[0];

endmodule

// This module calculates the final sum bits based on initial propagate signals and carries.
// The carries are derived from the prefix generate signals computed by the Kogge-Stone logic.
module sum_calculator (
    input [4:0] p_in,       // Initial propagate signals (extended)
    input [4:0] g_prefix_in, // Final prefix generate signals (from Kogge-Stone, G_i)
    output [4:0] sum         // Final sum bits (sum[0..3] are sum, sum[4] is carry-out)
);

// Carries into each bit position (carries_in[0] is the global carry_in)
// C_i = G_{i-1} | (P_{i-1} & C_{i-1})
// With global carry_in = 0, C_i = G_{i-1}
// carries_in[i] represents the carry into bit position i
wire [5:0] carries_in;

// Calculate carries into each bit position
// carries_in[0] is the carry into bit 0 (global carry-in)
// carries_in[i+1] is the carry into bit i+1, which is the prefix generate G_i
assign carries_in[0] = 1'b0; // Global carry-in is 0 for simple addition
assign carries_in[1] = g_prefix_in[0]; // Carry into bit 1 is G_0
assign carries_in[2] = g_prefix_in[1]; // Carry into bit 2 is G_1
assign carries_in[3] = g_prefix_in[2]; // Carry into bit 3 is G_2
assign carries_in[4] = g_prefix_in[3]; // Carry into bit 4 is G_3
assign carries_in[5] = g_prefix_in[4]; // Carry into bit 5 (carry-out) is G_4

// Calculate sum bits
// sum[i] = p_in[i] XOR carries_in[i]
assign sum[0] = p_in[0] ^ carries_in[0];
assign sum[1] = p_in[1] ^ carries_in[1];
assign sum[2] = p_in[2] ^ carries_in[2];
assign sum[3] = p_in[3] ^ carries_in[3];
assign sum[4] = p_in[4] ^ carries_in[4]; // This calculates the carry-out as the 5th bit of the sum vector

endmodule