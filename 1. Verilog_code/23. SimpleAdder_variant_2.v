module Adder_1(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

    // Signal declarations
    wire [3:0] p; // Propagate signals for each bit position
    wire [3:0] g; // Generate signals for each bit position

    // Block Generate and Propagate signals (Block size 2)
    // Block 0: bits [1:0]
    // Block 1: bits [3:2]
    wire [1:0] P_blk; // P_blk[0] for bits [1:0], P_blk[1] for bits [3:2]
    wire [1:0] G_blk; // G_blk[0] for bits [1:0], G_blk[1] for bits [3:2]

    // Carries into each bit position (carry_in_bit[i] is carry into bit i)
    wire [3:0] carry_in_bit; // carry_in_bit[0] is cin, carry_in_bit[1] is carry into bit 1, etc.

    // Carry into Block 1
    wire carry_in_blk1;

    // Overall carry out
    wire carry_out;

    // Sum bits
    wire [3:0] sum_bits;

    // 1. Level 0: Generate and Propagate signals for each bit
    assign g[0] = A[0] & B[0];
    assign p[0] = A[0] ^ B[0];
    assign g[1] = A[1] & B[1];
    assign p[1] = A[1] ^ B[1];
    assign g[2] = A[2] & B[2];
    assign p[2] = A[2] ^ B[2];
    assign g[3] = A[3] & B[3];
    assign p[3] = A[3] ^ B[3];

    // 2. Block P and G (Block size 2)
    // Block 0 (bits 1:0)
    assign P_blk[0] = p[1] & p[0];
    assign G_blk[0] = g[1] | (p[1] & g[0]);

    // Block 1 (bits 3:2)
    assign P_blk[1] = p[3] & p[2];
    assign G_blk[1] = g[3] | (p[3] & g[2]);

    // 3. Calculate carries
    // Carry into Block 0 (cin)
    assign carry_in_bit[0] = 1'b0;

    // Carry into Bit 1 (within Block 0)
    assign carry_in_bit[1] = g[0] | (p[0] & carry_in_bit[0]); // Ripple within block 0

    // Carry into Block 1 (carry out of Block 0)
    assign carry_in_blk1 = G_blk[0] | (P_blk[0] & carry_in_bit[0]); // Using block P/G and carry_in_bit[0] (cin)
    assign carry_in_bit[2] = carry_in_blk1; // Carry into bit 2

    // Carry into Bit 3 (within Block 1)
    assign carry_in_bit[3] = g[2] | (p[2] & carry_in_bit[2]); // Ripple within block 1

    // Overall Carry Out (carry out of Block 1)
    assign carry_out = G_blk[1] | (P_blk[1] & carry_in_blk1); // Using block P/G and carry_in_blk1

    // 4. Calculate sum bits
    // sum_bits[i] = p[i] ^ carry_in_bit[i]
    assign sum_bits[0] = p[0] ^ carry_in_bit[0];
    assign sum_bits[1] = p[1] ^ carry_in_bit[1];
    assign sum_bits[2] = p[2] ^ carry_in_bit[2];
    assign sum_bits[3] = p[3] ^ carry_in_bit[3];

    // 5. Final sum output is {carry_out, sum_bits}
    assign sum = {carry_out, sum_bits[3:0]};

endmodule