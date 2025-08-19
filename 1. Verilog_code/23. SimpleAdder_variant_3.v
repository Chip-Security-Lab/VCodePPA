//------------------------------------------------------------------------------
// Module: Adder_1
// Description: Top-level module for a 4-bit adder, using a hierarchical
//              ripple-carry structure.
// Inputs:
//   A, B: 4-bit input operands
// Outputs:
//   sum: 5-bit sum (including carry-out)
//------------------------------------------------------------------------------
module Adder_1 (
    input wire [3:0] A,
    input wire [3:0] B,
    output wire [4:0] sum
);

    // Internal wires for the 4-bit sum and the final carry-out from the adder core
    wire [3:0] adder_sum;
    wire adder_cout;

    // Instantiate the 4-bit ripple-carry adder submodule
    ripple_carry_adder_4bit adder_core (
        .A_in(A),
        .B_in(B),
        .sum_out(adder_sum),
        .cout(adder_cout)
    );

    // Concatenate the final carry-out and the 4-bit sum to form the 5-bit output
    assign sum = {adder_cout, adder_sum};

endmodule

//------------------------------------------------------------------------------
// Module: ripple_carry_adder_4bit
// Description: Implements a 4-bit ripple-carry adder using full adders.
// Inputs:
//   A_in: 4-bit input operand A
//   B_in: 4-bit input operand B
// Outputs:
//   sum_out: 4-bit sum output
//   cout: Final carry-out bit
//------------------------------------------------------------------------------
module ripple_carry_adder_4bit (
    input wire [3:0] A_in,
    input wire [3:0] B_in,
    output wire [3:0] sum_out,
    output wire cout
);

    // Internal wires for carries between stages
    wire c [3:0]; // c[0] is carry-out of stage 0, c[1] of stage 1, etc.

    // Stage 0 (LSB) - No carry-in, use 0
    full_adder fa0 (
        .a_in(A_in[0]),
        .b_in(B_in[0]),
        .cin(1'b0), // First stage has no carry-in
        .sum_out(sum_out[0]),
        .cout(c[0])
    );

    // Stage 1
    full_adder fa1 (
        .a_in(A_in[1]),
        .b_in(B_in[1]),
        .cin(c[0]), // Carry from previous stage
        .sum_out(sum_out[1]),
        .cout(c[1])
    );

    // Stage 2
    full_adder fa2 (
        .a_in(A_in[2]),
        .b_in(B_in[2]),
        .cin(c[1]), // Carry from previous stage
        .sum_out(sum_out[2]),
        .cout(c[2])
    );

    // Stage 3 (MSB)
    full_adder fa3 (
        .a_in(A_in[3]),
        .b_in(B_in[3]),
        .cin(c[2]), // Carry from previous stage
        .sum_out(sum_out[3]),
        .cout(c[3])
    );

    // The final carry-out is the carry-out of the MSB stage
    assign cout = c[3];

endmodule

//------------------------------------------------------------------------------
// Module: full_adder
// Description: Implements a single-bit full adder with optimized carry logic.
// Inputs:
//   a_in, b_in: Input bits
//   cin: Carry-in bit
// Outputs:
//   sum_out: Sum bit
//   cout: Carry-out bit
//------------------------------------------------------------------------------
module full_adder (
    input wire a_in,
    input wire b_in,
    input wire cin,
    output wire sum_out,
    output wire cout
);

    // Sum is the XOR of all three inputs (standard and optimal)
    assign sum_out = a_in ^ b_in ^ cin;

    // Carry-out is true if at least two of the three inputs are true
    // Optimized expression: cout = (a_in & b_in) | (a_in & cin) | (b_in & cin)
    assign cout = (a_in & b_in) | (a_in & cin) | (b_in & cin);

endmodule