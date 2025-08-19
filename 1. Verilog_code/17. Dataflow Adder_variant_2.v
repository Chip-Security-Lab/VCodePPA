module dataflow_adder_top(
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum,
    output cout
);

    wire [7:0] partial_sum;
    wire partial_cout;

    parallel_prefix_adder adder_inst (
        .a(a),
        .b(b),
        .partial_sum(partial_sum),
        .partial_cout(partial_cout)
    );

    output_handler out_handler_inst (
        .partial_sum(partial_sum),
        .partial_cout(partial_cout),
        .sum(sum),
        .cout(cout)
    );

endmodule

module parallel_prefix_adder(
    input [7:0] a,
    input [7:0] b,
    output [7:0] partial_sum,
    output partial_cout
);

    wire [7:0] g, p;
    wire [7:0] carry;
    wire [7:0] g_level1, p_level1;
    wire [7:0] g_level2, p_level2;
    wire [7:0] g_level3, p_level3;

    // Generate and propagate signals
    assign g[0] = a[0] & b[0];
    assign p[0] = a[0] ^ b[0];
    assign g[1] = a[1] & b[1];
    assign p[1] = a[1] ^ b[1];
    assign g[2] = a[2] & b[2];
    assign p[2] = a[2] ^ b[2];
    assign g[3] = a[3] & b[3];
    assign p[3] = a[3] ^ b[3];
    assign g[4] = a[4] & b[4];
    assign p[4] = a[4] ^ b[4];
    assign g[5] = a[5] & b[5];
    assign p[5] = a[5] ^ b[5];
    assign g[6] = a[6] & b[6];
    assign p[6] = a[6] ^ b[6];
    assign g[7] = a[7] & b[7];
    assign p[7] = a[7] ^ b[7];

    // Level 1
    assign g_level1[0] = g[0];
    assign p_level1[0] = p[0];
    assign g_level1[1] = g[1] | (p[1] & g[0]);
    assign p_level1[1] = p[1] & p[0];
    assign g_level1[2] = g[2] | (p[2] & g[1]);
    assign p_level1[2] = p[2] & p[1];
    assign g_level1[3] = g[3] | (p[3] & g[2]);
    assign p_level1[3] = p[3] & p[2];
    assign g_level1[4] = g[4] | (p[4] & g[3]);
    assign p_level1[4] = p[4] & p[3];
    assign g_level1[5] = g[5] | (p[5] & g[4]);
    assign p_level1[5] = p[5] & p[4];
    assign g_level1[6] = g[6] | (p[6] & g[5]);
    assign p_level1[6] = p[6] & p[5];
    assign g_level1[7] = g[7] | (p[7] & g[6]);
    assign p_level1[7] = p[7] & p[6];

    // Level 2
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    assign g_level2[1] = g_level1[1];
    assign p_level2[1] = p_level1[1];
    assign g_level2[2] = g_level1[2] | (p_level1[2] & g_level1[0]);
    assign p_level2[2] = p_level1[2] & p_level1[0];
    assign g_level2[3] = g_level1[3] | (p_level1[3] & g_level1[1]);
    assign p_level2[3] = p_level1[3] & p_level1[1];
    assign g_level2[4] = g_level1[4] | (p_level1[4] & g_level1[2]);
    assign p_level2[4] = p_level1[4] & p_level1[2];
    assign g_level2[5] = g_level1[5] | (p_level1[5] & g_level1[3]);
    assign p_level2[5] = p_level1[5] & p_level1[3];
    assign g_level2[6] = g_level1[6] | (p_level1[6] & g_level1[4]);
    assign p_level2[6] = p_level1[6] & p_level1[4];
    assign g_level2[7] = g_level1[7] | (p_level1[7] & g_level1[5]);
    assign p_level2[7] = p_level1[7] & p_level1[5];

    // Level 3
    assign g_level3[0] = g_level2[0];
    assign p_level3[0] = p_level2[0];
    assign g_level3[1] = g_level2[1];
    assign p_level3[1] = p_level2[1];
    assign g_level3[2] = g_level2[2];
    assign p_level3[2] = p_level2[2];
    assign g_level3[3] = g_level2[3];
    assign p_level3[3] = p_level2[3];
    assign g_level3[4] = g_level2[4] | (p_level2[4] & g_level2[0]);
    assign p_level3[4] = p_level2[4] & p_level2[0];
    assign g_level3[5] = g_level2[5] | (p_level2[5] & g_level2[1]);
    assign p_level3[5] = p_level2[5] & p_level2[1];
    assign g_level3[6] = g_level2[6] | (p_level2[6] & g_level2[2]);
    assign p_level3[6] = p_level2[6] & p_level2[2];
    assign g_level3[7] = g_level2[7] | (p_level2[7] & g_level2[3]);
    assign p_level3[7] = p_level2[7] & p_level2[3];

    // Carry computation
    assign carry[0] = 1'b0;
    assign carry[1] = g_level3[0] | (p_level3[0] & carry[0]);
    assign carry[2] = g_level3[1] | (p_level3[1] & carry[1]);
    assign carry[3] = g_level3[2] | (p_level3[2] & carry[2]);
    assign carry[4] = g_level3[3] | (p_level3[3] & carry[3]);
    assign carry[5] = g_level3[4] | (p_level3[4] & carry[4]);
    assign carry[6] = g_level3[5] | (p_level3[5] & carry[5]);
    assign carry[7] = g_level3[6] | (p_level3[6] & carry[6]);

    assign partial_sum = p ^ carry;
    assign partial_cout = carry[7];

endmodule

module output_handler(
    input [7:0] partial_sum,
    input partial_cout,
    output [7:0] sum,
    output cout
);

    assign sum = partial_sum;
    assign cout = partial_cout;

endmodule