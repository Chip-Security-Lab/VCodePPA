//============================================================================
// Top module: 4-bit Adder
// This module instantiates a parameterized ripple-carry adder
// configured for 4 bits. It serves as the top-level wrapper.
//============================================================================
module Adder_4 (
    input [3:0] A,   // First 4-bit input operand
    input [3:0] B,   // Second 4-bit input operand
    output [4:0] sum // 5-bit output sum (includes carry-out)
);

    // Instantiate the parameterized ripple-carry adder module
    // Configure it for N = 4 bits.
    // The parameterized module handles the ripple-carry chain internally.
    ripple_carry_adder #(
        .N (4) // Specify the number of bits for the adder
    ) rca_inst (
        .A     (A),     // Connect the first N-bit input
        .B     (B),     // Connect the second N-bit input
        .sum_o (sum)    // Connect the (N+1)-bit output sum (N bits + carry-out)
    );

endmodule

//============================================================================
// Submodule: Parameterized N-bit Ripple-Carry Adder
// This module implements an N-bit ripple-carry adder by instantiating
// N 1-bit full adders in a chain.
// It takes N-bit inputs and produces an (N+1)-bit output (sum + carry-out).
// Parameter N determines the width of the adder.
//============================================================================
module ripple_carry_adder #(
    parameter N = 4 // Default number of bits for the adder
) (
    input [N-1:0] A,     // First N-bit input operand
    input [N-1:0] B,     // Second N-bit input operand
    output [N:0]  sum_o  // (N+1)-bit output sum (includes final carry-out)
);

    // Internal wires to connect carry signals between full adders.
    // carry[0] is the carry-in to the LSB (bit 0).
    // carry[i] is the carry-in to bit i.
    // carry[i+1] is the carry-out from bit i.
    // carry[N] is the carry-out from the MSB (bit N-1), which becomes sum_o[N].
    wire [N:0] carry;

    // The carry-in to the least significant bit (bit 0) is always 0
    // for a standard adder operation without an external carry-in.
    assign carry[0] = 1'b0;

    // Generate block to instantiate N full_adder_1bit modules.
    // This loop creates the ripple-carry chain, connecting the carry-out
    // of each bit's adder to the carry-in of the next bit's adder.
    genvar i; // Generate loop variable
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_adder_bit
            // Instantiate a 1-bit full adder for each bit position (i)
            full_adder_1bit fa_inst (
                .a    (A[i]),         // Connect the i-th bit of input A
                .b    (B[i]),         // Connect the i-th bit of input B
                .cin  (carry[i]),     // Connect the carry-in for this bit (from previous stage)
                .s    (sum_o[i]),     // Connect the sum output for this bit
                .cout (carry[i+1])    // Connect the carry-out from this bit (to next stage)
            );
        end
    endgenerate

    // The final carry-out from the most significant bit's full adder (carry[N])
    // is already connected to sum_o[N] via the loop structure (specifically,
    // the last iteration where i = N-1 connects its cout to carry[N], which
    // is the signal connected to sum_o[N] in the port list).

endmodule

//============================================================================
// Submodule: 1-bit Full Adder
// This module performs the addition of two input bits (a, b) and a carry-in bit (cin).
// It produces a sum bit (s) and a carry-out bit (cout).
// Implemented using boolean logic expressions.
//============================================================================
module full_adder_1bit (
    input  a,   // First input bit
    input  b,   // Second input bit
    input  cin, // Carry-in bit
    output s,   // Sum bit (a XOR b XOR cin)
    output cout // Carry-out bit
);

    // Logic for the sum bit: sum = a XOR b XOR cin
    assign s = a ^ b ^ cin;

    // Logic for the carry-out bit: cout = (a AND b) OR (a AND cin) OR (b AND cin)
    // Alternative form: cout = (a AND b) OR (cin AND (a XOR b))
    // This alternative form can sometimes lead to different gate implementations
    // and potentially affect PPA (Power, Performance, Area).
    assign cout = (a & b) | (cin & (a ^ b));

endmodule