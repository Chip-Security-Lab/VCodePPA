// Top level module for a 4-bit adder using hierarchical design
// This module instantiates the ripple_carry_adder_4bit sub-module
// and combines the results to match the original 5-bit output
module Adder_2 (
    input wire [3:0] A,
    input wire [3:0] B,
    output wire [4:0] sum // Changed from reg to wire as it's combinational output
);

    wire [3:0] adder_sum_bits; // 4-bit sum output from the sub-module
    wire adder_carry_out;      // 1-bit carry-out output from the sub-module

    // Instantiate the 4-bit ripple carry adder sub-module
    ripple_carry_adder_4bit adder_inst (
        .A(A),                     // Connect input A
        .B(B),                     // Connect input B
        .sum(adder_sum_bits),      // Connect 4-bit sum output
        .cout(adder_carry_out)     // Connect carry-out output
    );

    // Combine the carry-out and the 4-bit sum to form the final 5-bit result
    // The carry-out becomes the most significant bit (MSB)
    assign sum = {adder_carry_out, adder_sum_bits};

endmodule

// 4-bit Ripple Carry Adder
// Adds two 4-bit numbers A and B
// Produces a 4-bit sum and a 1-bit carry-out
module ripple_carry_adder_4bit (
    input wire [3:0] A,
    input wire [3:0] B,
    output wire [3:0] sum,
    output wire cout
);

    wire [4:0] c; // Internal carries: c[0] is cin (tied to 0), c[1..3] are intermediate, c[4] is final cout

    // Tie carry-in of the first stage to 0 as per original functionality (A+B without explicit cin)
    assign c[0] = 1'b0;

    // Instantiate 4 full adders for each bit position
    full_adder fa0 (
        .a(A[0]),
        .b(B[0]),
        .cin(c[0]),      // Carry-in from previous stage (or 0 for the first stage)
        .sum(sum[0]),    // Sum bit for this stage
        .cout(c[1])      // Carry-out to the next stage
    );

    full_adder fa1 (
        .a(A[1]),
        .b(B[1]),
        .cin(c[1]),      // Carry-in from previous stage (c[1])
        .sum(sum[1]),    // Sum bit for this stage
        .cout(c[2])      // Carry-out to the next stage
    );

    full_adder fa2 (
        .a(A[2]),
        .b(B[2]),
        .cin(c[2]),      // Carry-in from previous stage (c[2])
        .sum(sum[2]),    // Sum bit for this stage
        .cout(c[3])      // Carry-out to the next stage
    );

    full_adder fa3 (
        .a(A[3]),
        .b(B[3]),
        .cin(c[3]),      // Carry-in from previous stage (c[3])
        .sum(sum[3]),    // Sum bit for this stage
        .cout(c[4])      // Carry-out to the next stage
    );

    // The final carry-out of the adder is the carry-out of the last stage
    assign cout = c[4];

endmodule

// Full Adder module
// Adds three 1-bit inputs (a, b, cin)
// Produces a 1-bit sum and a 1-bit carry-out
module full_adder (
    input wire a,
    input wire b,
    input wire cin,
    output wire sum,
    output wire cout
);

    // Sum calculation: a XOR b XOR cin
    assign sum = a ^ b ^ cin;

    // Optimized Carry-out logic using standard sum-of-products form
    // cout is 1 if at least two of a, b, cin are 1
    assign cout = (a & b) | (a & cin) | (b & cin);

endmodule