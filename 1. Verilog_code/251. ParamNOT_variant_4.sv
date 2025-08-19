//SystemVerilog
module Subtractor_8bit (
    input [7:0] operand_a,
    input [7:0] operand_b,
    output [7:0] result
);

    // Binary complement subtraction: a - b = a + (-b)
    // -b is represented as the two's complement of b
    wire [7:0] b_twos_complement;
    wire [8:0] sum_with_carry;

    // Calculate two's complement of b: ~b + 1
    assign b_twos_complement = (~operand_b) + 8'd1;

    // Perform addition: a + (-b)
    assign sum_with_carry = {1'b0, operand_a} + {1'b0, b_twos_complement};

    // The result is the lower 8 bits of the sum
    assign result = sum_with_carry[7:0];

endmodule