// full_adder module: Adds three bits (a, b, cin) and produces a sum bit and a carry-out bit.
// This is the basic building block for a ripple-carry adder.
module full_adder(
    input a,
    input b,
    input cin,
    output sum_out,
    output cout
);

    // Combinational logic for sum and carry-out
    assign sum_out = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));

endmodule


// Top-level module: Hierarchical 4-bit adder using full_adder submodules.
// Implements a ripple-carry adder structure.
module Adder_7_hierarchical(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

    // Internal wires to connect the carry signals between full_adder instances
    wire c_out_0; // Carry out from bit 0 adder
    wire c_out_1; // Carry out from bit 1 adder
    wire c_out_2; // Carry out from bit 2 adder
    wire c_out_3; // Carry out from bit 3 adder (becomes sum[4])

    // Instantiate full_adder for bit 0
    // Input carry is 0 for the least significant bit
    full_adder fa0 (
        .a(A[0]),
        .b(B[0]),
        .cin(1'b0), // Initial carry-in is 0
        .sum_out(sum[0]),
        .cout(c_out_0)
    );

    // Instantiate full_adder for bit 1
    // Input carry is the carry-out from the previous bit
    full_adder fa1 (
        .a(A[1]),
        .b(B[1]),
        .cin(c_out_0),
        .sum_out(sum[1]),
        .cout(c_out_1)
    );

    // Instantiate full_adder for bit 2
    // Input carry is the carry-out from the previous bit
    full_adder fa2 (
        .a(A[2]),
        .b(B[2]),
        .cin(c_out_1),
        .sum_out(sum[2]),
        .cout(c_out_2)
    );

    // Instantiate full_adder for bit 3
    // Input carry is the carry-out from the previous bit
    full_adder fa3 (
        .a(A[3]),
        .b(B[3]),
        .cin(c_out_2),
        .sum_out(sum[3]),
        .cout(c_out_3)
    );

    // The final carry-out from the most significant bit adder
    // becomes the most significant bit of the sum (sum[4])
    assign sum[4] = c_out_3;

    // Note: The original code declared 'sum' as 'reg' and assigned it in an 'always' block.
    // This implies a combinational assignment within the block.
    // In this hierarchical decomposition, the sum bits [3:0] and the carry bit [4]
    // are outputs of combinational logic (the full_adder modules and the final assign).
    // Assigning these combinational results to the 'sum' output port.
    // We keep 'sum' as output [4:0] wire as is typical for combinational outputs.
    // If a registered output was truly intended (a flip-flop on the sum),
    // a separate 'always @(posedge clk)' block would be needed to register the result.
    // Based on the original 'always @ (A or B)' sensitivity list, it was combinational.
    // The output is implicitly assigned by the submodule outputs and the final assign.

endmodule