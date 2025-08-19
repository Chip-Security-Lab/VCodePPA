// Sub-module to perform the core 4-bit addition logic
module four_bit_adder_core (
    input [3:0] a_in, // First 4-bit input operand
    input [3:0] b_in, // Second 4-bit input operand
    output [4:0] sum_out // 5-bit sum output
);

    // Perform the addition
    assign sum_out = a_in + b_in;

endmodule

// Top-level module for Adder_5
// This module instantiates the core adder sub-module
module Adder_5 (
    input [3:0] A, // First 4-bit input
    input [3:0] B, // Second 4-bit input
    output [4:0] sum // 5-bit sum output
);

    // Instantiate the four_bit_adder_core sub-module
    // Connect top-level ports to sub-module ports
    four_bit_adder_core u_adder_core (
        .a_in  (A),   // Connect top input A to sub-module input a_in
        .b_in  (B),   // Connect top input B to sub-module input b_in
        .sum_out (sum) // Connect sub-module output sum_out to top output sum
    );

endmodule