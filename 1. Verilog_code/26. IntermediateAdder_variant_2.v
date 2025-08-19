// Top-level module for a 4-bit Carry-Lookahead Adder
// Hierarchical structure
module Adder_4_hierarchical(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

    // Internal wires for intermediate signals
    wire [3:0] G0, P0;         // Initial Generate and Propagate signals
    wire [3:0] G1, P1;         // Stage 1 G and P signals (range size 2)
    wire [3:0] G2, P2;         // Stage 2 G and P signals (range size 4)
    wire [4:0] carry_in;       // Carry-in signals for each bit position

    // Instantiate the initial G/P generation module
    gp_gen #(
        .WIDTH(4)
    ) gp_gen_inst (
        .A(A),
        .B(B),
        .G0(G0),
        .P0(P0)
    );

    // Instantiate the first stage of Carry-Lookahead logic
    cla_stage1 cla_stage1_inst (
        .G0(G0),
        .P0(P0),
        .G1(G1),
        .P1(P1)
    );

    // Instantiate the second stage of Carry-Lookahead logic
    cla_stage2 cla_stage2_inst (
        .G1(G1),
        .P1(P1),
        .G2(G2),
        .P2(P2)
    );

    // Instantiate the module to calculate carries
    carry_calc carry_calc_inst (
        .G0(G0),
        .G1(G1),
        .G2(G2),
        .carry_in(carry_in)
    );

    // Instantiate the module to calculate the final sum bits
    sum_calc #(
        .WIDTH(4)
    ) sum_calc_inst (
        .P0(P0),
        .carry_in(carry_in),
        .sum(sum)
    );

endmodule


// Submodule to generate initial Generate (G0) and Propagate (P0) signals
// G0[i] = A[i] & B[i]
// P0[i] = A[i] ^ B[i]
module gp_gen #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] A,
    input [WIDTH-1:0] B,
    output [WIDTH-1:0] G0,
    output [WIDTH-1:0] P0
);

    assign G0 = A & B;
    assign P0 = A ^ B;

endmodule


// Submodule for Stage 1 Carry-Lookahead logic
// Computes G1 and P1 for ranges of size 2
module cla_stage1 (
    input [3:0] G0,
    input [3:0] P0,
    output [3:0] G1,
    output [3:0] P1
);

    // i=0: Passthrough (range [0:0])
    assign G1[0] = G0[0];
    assign P1[0] = P0[0];
    // i=1: Range [1:0]
    assign G1[1] = G0[1] | (P0[1] & G0[0]);
    assign P1[1] = P0[1] & P0[0];
    // i=2: Range [2:1]
    assign G1[2] = G0[2] | (P0[2] & G0[1]);
    assign P1[2] = P0[2] & P0[1];
    // i=3: Range [3:2]
    assign G1[3] = G0[3] | (P0[3] & G0[2]);
    assign P1[3] = P0[3] & P0[2];

endmodule


// Submodule for Stage 2 Carry-Lookahead logic
// Computes G2 and P2 for ranges of size 4
module cla_stage2 (
    input [3:0] G1,
    input [3:0] P1,
    output [3:0] G2,
    output [3:0] P2
);

    // i=0: Passthrough (range [0:0])
    assign G2[0] = G1[0];
    assign P2[0] = P1[0];
    // i=1: Passthrough (range [1:0])
    assign G2[1] = G1[1];
    assign P2[1] = P1[1];
    // i=2: Range [2:0]
    assign G2[2] = G1[2] | (P1[2] & G1[0]);
    assign P2[2] = P1[2] & P1[0];
    // i=3: Range [3:0]
    assign G2[3] = G1[3] | (P1[3] & G1[1]);
    assign P2[3] = P1[3] & P1[1];

endmodule


// Submodule to calculate the carry-in signals for each bit position
// Uses G signals from different stages
module carry_calc (
    input [3:0] G0,
    input [3:0] G1,
    input [3:0] G2,
    output [4:0] carry_in
);

    assign carry_in[0] = 1'b0;  // External carry-in is 0
    assign carry_in[1] = G0[0]; // Carry into bit 1 is G over range [0:0]
    assign carry_in[2] = G1[1]; // Carry into bit 2 is G over range [1:0]
    assign carry_in[3] = G2[2]; // Carry into bit 3 is G over range [2:0]
    assign carry_in[4] = G2[3]; // Carry-out is G over range [3:0]

endmodule


// Submodule to calculate the final sum bits
// sum[i] = P0[i] ^ carry_in[i]
// sum[WIDTH] = carry_in[WIDTH] (Carry-out)
module sum_calc #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] P0,
    input [WIDTH:0] carry_in,
    output [WIDTH:0] sum
);

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : sum_bits
            assign sum[i] = P0[i] ^ carry_in[i];
        end
    endgenerate

    assign sum[WIDTH] = carry_in[WIDTH]; // Carry-out

endmodule