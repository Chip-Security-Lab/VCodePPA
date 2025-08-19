module dataflow_adder_top(
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum,
    output cout
);

    wire [7:0] partial_sum;
    wire partial_cout;

    adder_core u_adder_core(
        .a(a),
        .b(b),
        .partial_sum(partial_sum),
        .partial_cout(partial_cout)
    );

    output_formatter u_output_formatter(
        .partial_sum(partial_sum),
        .partial_cout(partial_cout),
        .sum(sum),
        .cout(cout)
    );

endmodule

module adder_core(
    input [7:0] a,
    input [7:0] b,
    output [7:0] partial_sum,
    output partial_cout
);

    wire [7:0] carry;
    wire [7:0] g = a & b;
    wire [7:0] p = a ^ b;

    // Optimized carry computation using Kogge-Stone structure
    wire [7:0] g_level1, p_level1;
    wire [7:0] g_level2, p_level2;
    wire [7:0] g_level3, p_level3;

    // Level 1
    assign g_level1[0] = g[0];
    assign p_level1[0] = p[0];
    genvar i;
    generate
        for(i=1; i<8; i=i+1) begin: level1
            assign g_level1[i] = g[i] | (p[i] & g[i-1]);
            assign p_level1[i] = p[i] & p[i-1];
        end
    endgenerate

    // Level 2
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    assign g_level2[1] = g_level1[1];
    assign p_level2[1] = p_level1[1];
    generate
        for(i=2; i<8; i=i+1) begin: level2
            assign g_level2[i] = g_level1[i] | (p_level1[i] & g_level1[i-2]);
            assign p_level2[i] = p_level1[i] & p_level1[i-2];
        end
    endgenerate

    // Level 3
    assign g_level3[0] = g_level2[0];
    assign p_level3[0] = p_level2[0];
    assign g_level3[1] = g_level2[1];
    assign p_level3[1] = p_level2[1];
    assign g_level3[2] = g_level2[2];
    assign p_level3[2] = p_level2[2];
    assign g_level3[3] = g_level2[3];
    assign p_level3[3] = p_level2[3];
    generate
        for(i=4; i<8; i=i+1) begin: level3
            assign g_level3[i] = g_level2[i] | (p_level2[i] & g_level2[i-4]);
            assign p_level3[i] = p_level2[i] & p_level2[i-4];
        end
    endgenerate

    // Final carry computation
    assign carry = g_level3 | (p_level3 & {1'b0, g_level3[6:0]});

    // Optimized sum computation
    assign partial_sum = p ^ {carry[6:0], 1'b0};
    assign partial_cout = carry[7];

endmodule

module output_formatter(
    input [7:0] partial_sum,
    input partial_cout,
    output [7:0] sum,
    output cout
);

    assign sum = partial_sum;
    assign cout = partial_cout;

endmodule