module cla_adder(
    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output cout
);

    // Generate and propagate signals
    wire [3:0] g = a & b;
    wire [3:0] p = a ^ b;
    wire [3:0] c;

    // First level carry lookahead
    wire [3:0] g_1, p_1;
    assign g_1[0] = g[0];
    assign p_1[0] = p[0];
    assign g_1[1] = g[1] | (p[1] & g[0]);
    assign p_1[1] = p[1] & p[0];
    assign g_1[2] = g[2] | (p[2] & g[1]);
    assign p_1[2] = p[2] & p[1];
    assign g_1[3] = g[3] | (p[3] & g[2]);
    assign p_1[3] = p[3] & p[2];

    // Second level carry lookahead
    wire [1:0] g_2, p_2;
    assign g_2[0] = g_1[0];
    assign p_2[0] = p_1[0];
    assign g_2[1] = g_1[2] | (p_1[2] & g_1[0]);
    assign p_2[1] = p_1[2] & p_1[0];

    // Final carry generation
    assign c[0] = cin;
    assign c[1] = g_1[0] | (p_1[0] & cin);
    assign c[2] = g_1[2] | (p_1[2] & c[0]);
    assign c[3] = g_1[3] | (p_1[3] & g_2[0]) | (p_1[3] & p_2[0] & cin);

    // Sum and carry out
    assign sum = p ^ {c[2:0], cin};
    assign cout = g_1[3] | (p_1[3] & g_2[0]) | (p_1[3] & p_2[0] & cin);

endmodule