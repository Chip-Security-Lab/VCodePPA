// Top module: 4-bit Adder
// Instantiates the core addition logic
// This module serves as the top-level interface for the adder.
module Adder_8(
    input [3:0] A,  // First 4-bit operand
    input [3:0] B,  // Second 4-bit operand
    output [4:0] sum // 5-bit result (sum including carry)
);

    // Internal wire to connect the output of the core adder sub-module to the top module output
    wire [4:0] w_sum_internal;

    // Instantiate the core addition sub-module
    // This sub-module encapsulates the primary arithmetic operation.
    AddCore_4Bit core_adder (
        .in_A(A),             // Connect top module input A to sub-module input in_A
        .in_B(B),             // Connect top module input B to sub_module input in_B
        .out_sum(w_sum_internal) // Connect sub-module output out_sum to internal wire
    );

    // Assign the result from the internal wire to the top module output port
    assign sum = w_sum_internal;

endmodule

// Sub-module: Performs the core 4-bit addition using Carry Lookahead Logic
// Takes two 4-bit inputs and produces a 5-bit sum (including carry).
// This module is a functional unit responsible for the addition operation.
module AddCore_4Bit(
    input [3:0] in_A, // First 4-bit operand
    input [3:0] in_B, // Second 4-bit operand
    output [4:0] out_sum // 5-bit result (sum and carry)
);

    // Internal signals for Carry Lookahead Adder
    wire [3:0] generate_g; // Generate signals G_i = A_i & B_i
    wire [3:0] propagate_p; // Propagate signals P_i = A_i ^ B_i
    wire [4:0] carry_c;     // Carry signals C_{i+1}

    // Calculate Generate and Propagate signals for each bit
    assign generate_g = in_A & in_B;
    assign propagate_p = in_A ^ in_B;

    // Assume carry-in to the LSB (C0) is 0
    assign carry_c[0] = 1'b0; // C_0

    // Calculate carry signals using Carry Lookahead logic
    // C_{i+1} derived from G_j, P_j (j<=i) and C_0

    // C1 = G0 + P0*C0
    assign carry_c[1] = generate_g[0] | (propagate_p[0] & carry_c[0]);

    // C2 = G1 + P1*C1 = G1 + P1*(G0 + P0*C0) = G1 + P1*G0 + P1*P0*C0
    assign carry_c[2] = generate_g[1] | (propagate_p[1] & generate_g[0]) | (propagate_p[1] & propagate_p[0] & carry_c[0]);

    // C3 = G2 + P2*C2 = G2 + P2*(G1 + P1*G0 + P1*P0*C0) = G2 + P2*G1 + P2*P1*G0 + P2*P1*P0*C0
    assign carry_c[3] = generate_g[2] | (propagate_p[2] & generate_g[1]) | (propagate_p[2] & propagate_p[1] & generate_g[0]) | (propagate_p[2] & propagate_p[1] & propagate_p[0] & carry_c[0]);

    // C4 = G3 + P3*C3 = G3 + P3*(G2 + P2*G1 + P2*P1*G0 + P2*P1*P0*C0)
    assign carry_c[4] = generate_g[3] | (propagate_p[3] & generate_g[2]) | (propagate_p[3] & propagate_p[2] & generate_g[1]) | (propagate_p[3] & propagate_p[2] & propagate_p[1] & generate_g[0]) | (propagate_p[3] & propagate_p[2] & propagate_p[1] & propagate_p[0] & carry_c[0]);


    // Calculate sum bits
    // S_i = P_i ^ C_i
    wire [3:0] sum_bits;
    assign sum_bits[0] = propagate_p[0] ^ carry_c[0]; // S0 = P0 ^ C0
    assign sum_bits[1] = propagate_p[1] ^ carry_c[1]; // S1 = P1 ^ C1
    assign sum_bits[2] = propagate_p[2] ^ carry_c[2]; // S2 = P2 ^ C2
    assign sum_bits[3] = propagate_p[3] ^ carry_c[3]; // S3 = P3 ^ C3

    // Concatenate carry-out and sum bits for the final result
    // The carry-out is C4
    assign out_sum = {carry_c[4], sum_bits};

endmodule