module Adder_6(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

    // Implement A - B using A + (~B) + 1
    // Use a 5-bit conditional sum adder structure for the addition
    // A - B (4-bit unsigned) is equivalent to
    // {1'b0, A[3:0]} + {1'b1, ~B[3:0]} + 1'b1
    // This computes the 5-bit two's complement result of A - B.

    wire [4:0] a_extended = {1'b0, A};       // Extend A to 5 bits
    wire [4:0] b_inverted = {1'b1, ~B};      // Compute ~B extended to 5 bits

    // Conditional Sum Adder structure for a_extended + b_inverted + 1'b1
    // Divide into blocks: [1:0], [3:2], [4]
    // Initial carry-in (cin_block0) is 1'b1

    // Block 0 (bits [1:0]) - Fixed Cin = 1
    wire [1:0] block0_sum;
    wire block0_carry_out;
    // 2-bit addition with cin requires 3 bits for result {cout, sum}
    assign {block0_carry_out, block0_sum} = a_extended[1:0] + b_inverted[1:0] + 1'b1;
    assign sum[1:0] = block0_sum;

    // Block 1 (bits [3:2]) - Cin depends on block0_carry_out
    wire [1:0] block1_sum_cin0; // Sum if Cin = 0
    wire block1_carry_out_cin0; // Cout if Cin = 0
    // 2-bit addition with cin requires 3 bits for result {cout, sum}
    assign {block1_carry_out_cin0, block1_sum_cin0} = a_extended[3:2] + b_inverted[3:2] + 1'b0;

    wire [1:0] block1_sum_cin1; // Sum if Cin = 1
    wire block1_carry_out_cin1; // Cout if Cin = 1
    // 2-bit addition with cin requires 3 bits for result {cout, sum}
    assign {block1_carry_out_cin1, block1_sum_cin1} = a_extended[3:2] + b_inverted[3:2] + 1'b1;

    wire block1_actual_cin = block0_carry_out; // Carry-in to block 1 is carry-out from block 0
    wire block1_actual_carry_out;             // Actual carry-out from block 1

    assign sum[3:2] = block1_actual_cin ? block1_sum_cin1 : block1_sum_cin0;
    assign block1_actual_carry_out = block1_actual_cin ? block1_carry_out_cin1 : block1_carry_out_cin0;

    // Block 2 (bit [4]) - Cin depends on block1_actual_carry_out
    wire block2_sum_cin0; // Sum if Cin = 0
    wire block2_carry_out_cin0; // Cout if Cin = 0
    // 1-bit addition with cin requires 2 bits for result {cout, sum}
    assign {block2_carry_out_cin0, block2_sum_cin0} = a_extended[4] + b_inverted[4] + 1'b0;

    wire block2_sum_cin1; // Sum if Cin = 1
    wire block2_carry_out_cin1; // Cout if Cin = 1
    // 1-bit addition with cin requires 2 bits for result {cout, sum}
    assign {block2_carry_out_cin1, block2_sum_cin1} = a_extended[4] + b_inverted[4] + 1'b1;

    wire block2_actual_cin = block1_actual_carry_out; // Carry-in to block 2 is carry-out from block 1
    // wire block2_actual_carry_out;                   // Actual carry-out from block 2 (final borrow out)

    assign sum[4] = block2_actual_cin ? block2_sum_cin1 : block2_sum_cin0;
    // assign block2_actual_carry_out = block2_actual_cin ? block2_carry_out_cin1 : block2_carry_out_cin0; // Final carry/borrow

    // The output 'sum' is 5 bits, which is the result of the 5-bit addition
    // {1'b0, A} + {1'b1, ~B} + 1'b1, representing A - B in 5-bit two's complement.

endmodule