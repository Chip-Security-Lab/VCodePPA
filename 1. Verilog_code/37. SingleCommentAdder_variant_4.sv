//SystemVerilog
// 8-bit Carry-Lookahead Adder (CLA) using 4-bit blocks

// Top module: 8-bit adder
module adder_5 (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire       cin,
    output wire [7:0] sum,
    output wire       cout
);

    // Internal signals for block Generate (G_block) and Propagate (P_block)
    wire P_block0, G_block0; // Group P and G for bits 3:0 (block 0)
    wire P_block1, G_block1; // Group P and G for bits 7:4 (block 1)

    // Carry signal between blocks (carry-in for block 1), calculated using group logic
    wire c_block1_in; // This is the calculated carry c[4]

    // Instantiate the first 4-bit CLA block (bits 3:0)
    cla_4bit block0 (
        .a(a[3:0]),
        .b(b[3:0]),
        .cin(cin),         // Top-level carry-in
        .sum(sum[3:0]),
        .cout(),           // Internal block cout not used directly for cascading carry
        .P_block(P_block0),
        .G_block(G_block0)
    );

    // Calculate the carry-in for the second block (c[4]) using group signals from block0
    // c[4] = G_block0 | (P_block0 & c[0])
    assign c_block1_in = G_block0 | (P_block0 & cin);

    // Instantiate the second 4-bit CLA block (bits 7:4)
    cla_4bit block1 (
        .a(a[7:4]),
        .b(b[7:4]),
        .cin(c_block1_in), // Use the calculated fast carry
        .sum(sum[7:4]),
        .cout(cout),       // Carry out of block 1 is the final carry-out
        .P_block(P_block1), // P_block1 and G_block1 are not strictly needed at the top level for an 8-bit adder
        .G_block(G_block1)  // unless building a wider adder (e.g., 16-bit) from 8-bit blocks.
    );

    // The final carry-out is the carry-out of the last block (block1).

endmodule

// Sub-module: 4-bit Carry-Lookahead Adder Block
// This block calculates sum bits and provides group P and G signals.
module cla_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    input wire       cin,
    output wire [3:0] sum,
    output wire       cout,      // Carry out of this block (c[4])
    output wire       P_block,   // Block Propagate (P_block = p3 & p2 & p1 & p0)
    output wire       G_block    // Block Generate (G_block = g3 | (p3&g2) | (p3&p2&p1&g0))
);

    // Internal signals for bit Generate (g_i) and Propagate (p_i)
    wire [3:0] g; // g_i = a_i & b_i
    wire [3:0] p; // p_i = a_i | b_i (using a|b for propagate)

    // Internal signals for carries within the block (c[0]=cin, c[4]=cout)
    // We only need c[0] through c[3] for the sum calculation
    wire [3:0] c; // c[0]..c[3]

    // 1. Calculate bit Generate and Propagate signals
    assign g = a & b;
    assign p = a | b;

    // c[0] is the input carry
    assign c[0] = cin;

    // 3. Calculate internal carries c[1]..c[3] using expanded CLA logic
    // c[i+1] = g[i] | (p[i] & c[i]) -- expanded form
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);

    // 4. Calculate sum bits
    // sum[i] = a[i] ^ b[i] ^ c[i]
    assign sum = (a ^ b) ^ c; // Vector XOR with c[0]..c[3]

    // 5. Calculate Block Generate and Propagate signals
    // These are needed for faster carry calculation at the next level (e.g., in the top module)
    assign G_block = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    assign P_block = p[3] & p[2] & p[1] & p[0];

    // 6. Calculate block carry-out using G_block, P_block, and cin
    // This replaces the direct calculation of c[4] using the full expansion
    assign cout = G_block | (P_block & cin);

endmodule