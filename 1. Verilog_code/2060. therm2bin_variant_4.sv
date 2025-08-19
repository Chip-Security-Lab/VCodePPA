//SystemVerilog
// Top-level module: Hierarchical thermometer-to-binary encoder
module therm2bin #(
    parameter THERM_WIDTH = 7,
    parameter BIN_WIDTH = 3 // $clog2(THERM_WIDTH+1) = 3 for 7 bits
)(
    input  wire [THERM_WIDTH-1:0] therm_in,
    output wire [BIN_WIDTH-1:0]   bin_out
);

    // Internal signal for the population count result
    wire [BIN_WIDTH-1:0] popcount_bk_result;

    // Instantiate the population count submodule using Brent-Kung adder
    popcount_bk #(
        .IN_WIDTH(THERM_WIDTH),
        .OUT_WIDTH(BIN_WIDTH)
    ) u_popcount_bk (
        .in_vec(therm_in),
        .pop_count(popcount_bk_result)
    );

    // Output assignment
    assign bin_out = popcount_bk_result;

endmodule

// --------------------------------------------------------------------------
// Submodule: Population Count (Popcount) Using Brent-Kung Adder
// This module counts the number of '1's in the input vector using a Brent-Kung adder tree.
// Parameterized for input and output width.
// --------------------------------------------------------------------------
module popcount_bk #(
    parameter IN_WIDTH = 7,
    parameter OUT_WIDTH = 3 // $clog2(IN_WIDTH+1)
)(
    input  wire [IN_WIDTH-1:0] in_vec,
    output wire [OUT_WIDTH-1:0] pop_count
);

    // Internal wires for 1-bit values
    wire [6:0] bit_in;
    assign bit_in = in_vec[6:0];

    // First level: Pairwise addition (2-bit Brent-Kung adders)
    wire [2:0] sum_lvl1;
    wire [2:0] carry_lvl1;

    brent_kung_adder_2 u_bk_adder1 (.a(bit_in[0]), .b(bit_in[1]), .sum(sum_lvl1[0]), .cout(carry_lvl1[0]));
    brent_kung_adder_2 u_bk_adder2 (.a(bit_in[2]), .b(bit_in[3]), .sum(sum_lvl1[1]), .cout(carry_lvl1[1]));
    brent_kung_adder_2 u_bk_adder3 (.a(bit_in[4]), .b(bit_in[5]), .sum(sum_lvl1[2]), .cout(carry_lvl1[2]));

    // Last input bit passes as is
    wire bit_last = bit_in[6];

    // Second level: Add previous results (3-bit and 2-bit adders)
    wire [2:0] add_lvl2_in1;
    assign add_lvl2_in1 = {carry_lvl1[1], sum_lvl1[1], carry_lvl1[0]}; // {carry, sum, carry}
    wire [2:0] add_lvl2_in2;
    assign add_lvl2_in2 = {sum_lvl1[2], carry_lvl1[2], bit_last};

    wire [2:0] sum_lvl2;
    wire       carry_lvl2;

    brent_kung_adder_3 u_bk_adder4 (
        .a({carry_lvl1[2], sum_lvl1[2], bit_last}),
        .b({carry_lvl1[1], sum_lvl1[1], carry_lvl1[0]}),
        .sum(sum_lvl2),
        .cout(carry_lvl2)
    );

    // Final level: Sum all together (3-bit Brent-Kung adder)
    wire [2:0] sum_final;
    wire       carry_final;

    brent_kung_adder_3 u_bk_adder5 (
        .a(sum_lvl2),
        .b({2'b00, sum_lvl1[0]}), // pad to 3 bits, add sum_lvl1[0]
        .sum(sum_final),
        .cout(carry_final)
    );

    // Assemble the result
    assign pop_count = {carry_final, sum_final};

endmodule

// --------------------------------------------------------------------------
// 2-bit Brent-Kung Adder
// Adds two 1-bit inputs, outputs 1-bit sum and carry
// --------------------------------------------------------------------------
module brent_kung_adder_2 (
    input  wire a,
    input  wire b,
    output wire sum,
    output wire cout
);
    assign sum  = a ^ b;
    assign cout = a & b;
endmodule

// --------------------------------------------------------------------------
// 3-bit Brent-Kung Adder
// Adds two 3-bit inputs, outputs 3-bit sum and carry
// --------------------------------------------------------------------------
module brent_kung_adder_3 (
    input  wire [2:0] a,
    input  wire [2:0] b,
    output wire [2:0] sum,
    output wire       cout
);
    wire [2:0] g, p, c;

    // Generate and Propagate
    assign g = a & b;
    assign p = a ^ b;

    // Carry chain (Brent-Kung style for 3 bits)
    assign c[0] = 1'b0;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]);
    assign cout = g[2] | (p[2] & g[1] | (p[2] & p[1] & g[0]));

    // Sum
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
endmodule