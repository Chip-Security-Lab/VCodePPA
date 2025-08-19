// Top level module: Hierarchical 4-bit Adder
// Instantiates the core adder logic submodule to perform the addition.
module Adder_3_hierarchical (
    input [3:0] A,  // First 4-bit input operand
    input [3:0] B,  // Second 4-bit input operand
    output [4:0] sum // 5-bit output sum (includes carry-out)
);

    // Internal wire to connect the submodule's output to the top module's output
    wire [4:0] w_core_sum;

    // Instantiate the core adder submodule
    // This submodule encapsulates the actual addition logic.
    adder_core_4bit u_adder_core (
        .i_A(A),         // Connect input A to submodule input i_A
        .i_B(B),         // Connect input B to submodule input i_B
        .o_sum(w_core_sum) // Connect submodule output o_sum to internal wire w_core_sum
    );

    // Assign the result from the submodule to the top module's output
    assign sum = w_core_sum;

endmodule

// Submodule: Core 4-bit Addition Logic
// Performs the addition of two 4-bit inputs and produces a 5-bit sum (including carry).
// This module contains the fundamental arithmetic operation.
module adder_core_4bit (
    input [3:0] i_A, // First 4-bit input operand for addition
    input [3:0] i_B, // Second 4-bit input operand for addition
    output [4:0] o_sum // 5-bit output sum resulting from the addition (includes carry-out)
);

    // Perform the 4-bit addition using the built-in '+' operator.
    // Concatenate a '0' bit (1'b0) to both operands before adding.
    // This extends the operands to 5 bits, ensuring the carry-out of the 4-bit addition
    // is captured as the most significant bit (MSB) of the 5-bit result.
    assign o_sum = {1'b0, i_A} + {1'b0, i_B};

endmodule