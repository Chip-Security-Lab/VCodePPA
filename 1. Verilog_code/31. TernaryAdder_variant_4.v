module Adder_9(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

    // sum is a wire assigned continuously
    wire [4:0] sum;

    // Calculate the sum using a continuous assignment
    // This replaces the always block and if-else structure,
    // directly implementing the addition which was the effective result
    // of the original logic after removing the redundancy.
    assign sum = A + B;

endmodule