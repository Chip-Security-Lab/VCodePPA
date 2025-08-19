// Top-level module for a 4-bit adder using ripple-carry full adders
// This module decomposes the 4-bit addition into a chain of 1-bit full adders.
module Adder_8(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

    // Internal wires for carry chain between full adders
    wire [3:0] carry;

    // Instantiate 1-bit full adders for each bit position (0 to 3)
    // The carry-out of each stage becomes the carry-in of the next stage.

    // fa0: Adds bits 0 of A and B with carry-in 0 (for LSB)
    full_adder fa0 (
        .a       (A[0]),
        .b       (B[0]),
        .cin     (1'b0),     // Carry-in for the least significant bit is 0
        .sum_out (sum[0]),
        .cout    (carry[0])
    );

    // fa1: Adds bits 1 of A and B with carry from previous stage (carry[0])
    full_adder fa1 (
        .a       (A[1]),
        .b       (B[1]),
        .cin     (carry[0]), // Carry-in from bit 0 stage
        .sum_out (sum[1]),
        .cout    (carry[1])
    );

    // fa2: Adds bits 2 of A and B with carry from previous stage (carry[1])
    full_adder fa2 (
        .a       (A[2]),
        .b       (B[2]),
        .cin     (carry[1]), // Carry-in from bit 1 stage
        .sum_out (sum[2]),
        .cout    (carry[2])
    );

    // fa3: Adds bits 3 of A and B with carry from previous stage (carry[2])
    full_adder fa3 (
        .a       (A[3]),
        .b       (B[3]),
        .cin     (carry[2]), // Carry-in from bit 2 stage
        .sum_out (sum[3]),
        .cout    (carry[3])
    );

    // The final carry-out from the most significant bit stage (bit 3)
    // becomes the most significant bit of the 5-bit sum.
    assign sum[4] = carry[3];

endmodule

// 1-bit Full Adder module
// Adds three 1-bit inputs (a, b, cin) and produces a 1-bit sum (sum_out)
// and a 1-bit carry-out (cout).
module full_adder(
    input  a,
    input  b,
    input  cin,
    output sum_out,
    output cout
);

    // Combinational logic for sum and carry-out
    // Sum is the XOR of the three inputs
    assign sum_out = a ^ b ^ cin;

    // Carry-out is 1 if any two or all three inputs are 1
    // Using sum-of-products form for carry-out
    assign cout    = (a & b) | (a & cin) | (b & cin);

endmodule