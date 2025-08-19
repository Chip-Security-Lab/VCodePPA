module subtractor_8bit_borrow_detect (
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff,
    output borrow
);

    wire [7:0] b_comp;
    wire [7:0] g, p;
    wire [7:0] c;

    // Complement module
    complement_8bit comp_inst (
        .b(b),
        .b_comp(b_comp)
    );

    // Generate and Propagate module
    gp_generator gp_inst (
        .a(a),
        .b_comp(b_comp),
        .g(g),
        .p(p)
    );

    // Parallel Prefix Network module
    wire [7:0] g3, p3;
    parallel_prefix_network ppn_inst (
        .g(g),
        .p(p),
        .g_out(g3),
        .p_out(p3)
    );

    // Carry and Sum module
    carry_sum_generator csg_inst (
        .g3(g3),
        .p(p),
        .c(c),
        .borrow(borrow),
        .diff(diff)
    );

endmodule

module complement_8bit (
    input [7:0] b,
    output [7:0] b_comp
);
    assign b_comp = ~b;
endmodule

module gp_generator (
    input [7:0] a,
    input [7:0] b_comp,
    output [7:0] g,
    output [7:0] p
);
    assign g = a & b_comp;
    assign p = a ^ b_comp;
endmodule

module parallel_prefix_network (
    input [7:0] g,
    input [7:0] p,
    output [7:0] g_out,
    output [7:0] p_out
);
    wire [7:0] g1, p1;
    wire [7:0] g2, p2;

    // First level
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[3] = p[3] & p[2];
    assign g1[4] = g[4] | (p[4] & g[3]);
    assign p1[4] = p[4] & p[3];
    assign g1[5] = g[5] | (p[5] & g[4]);
    assign p1[5] = p[5] & p[4];
    assign g1[6] = g[6] | (p[6] & g[5]);
    assign p1[6] = p[6] & p[5];
    assign g1[7] = g[7] | (p[7] & g[6]);
    assign p1[7] = p[7] & p[6];

    // Second level
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];
    assign g2[4] = g1[4] | (p1[4] & g1[2]);
    assign p2[4] = p1[4] & p1[2];
    assign g2[5] = g1[5] | (p1[5] & g1[3]);
    assign p2[5] = p1[5] & p1[3];
    assign g2[6] = g1[6] | (p1[6] & g1[4]);
    assign p2[6] = p1[6] & p1[4];
    assign g2[7] = g1[7] | (p1[7] & g1[5]);
    assign p2[7] = p1[7] & p1[5];

    // Third level
    assign g_out[0] = g2[0];
    assign p_out[0] = p2[0];
    assign g_out[1] = g2[1];
    assign p_out[1] = p2[1];
    assign g_out[2] = g2[2];
    assign p_out[2] = p2[2];
    assign g_out[3] = g2[3];
    assign p_out[3] = p2[3];
    assign g_out[4] = g2[4] | (p2[4] & g2[0]);
    assign p_out[4] = p2[4] & p2[0];
    assign g_out[5] = g2[5] | (p2[5] & g2[1]);
    assign p_out[5] = p2[5] & p2[1];
    assign g_out[6] = g2[6] | (p2[6] & g2[2]);
    assign p_out[6] = p2[6] & p2[2];
    assign g_out[7] = g2[7] | (p2[7] & g2[3]);
    assign p_out[7] = p2[7] & p2[3];
endmodule

module carry_sum_generator (
    input [7:0] g3,
    input [7:0] p,
    output [7:0] c,
    output borrow,
    output [7:0] diff
);
    assign c[0] = 1'b0;
    assign c[1] = g3[0];
    assign c[2] = g3[1];
    assign c[3] = g3[2];
    assign c[4] = g3[3];
    assign c[5] = g3[4];
    assign c[6] = g3[5];
    assign c[7] = g3[6];
    assign borrow = g3[7];
    assign diff = p ^ {c[6:0], 1'b0};
endmodule