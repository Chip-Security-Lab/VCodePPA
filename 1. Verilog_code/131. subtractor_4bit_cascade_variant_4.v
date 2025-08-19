// Top level module
module subtractor_4bit_parallel (
    input [3:0] a,
    input [3:0] b, 
    output [3:0] diff,
    output borrow
);

    // Internal signals
    wire [3:0] g, p;
    wire [3:0] g_level1, p_level1;
    wire [3:0] g_level2, p_level2;
    wire [3:0] g_level3, p_level3;

    // Instantiate submodules
    gp_generator gp_gen (
        .a(a),
        .b(b),
        .g(g),
        .p(p)
    );

    level1_compute l1_comp (
        .g(g),
        .p(p),
        .g_out(g_level1),
        .p_out(p_level1)
    );

    level2_compute l2_comp (
        .g_in(g_level1),
        .p_in(p_level1),
        .g_out(g_level2),
        .p_out(p_level2)
    );

    level3_compute l3_comp (
        .g_in(g_level2),
        .p_in(p_level2),
        .g_out(g_level3),
        .p_out(p_level3)
    );

    final_compute final_comp (
        .p(p),
        .g_level3(g_level3),
        .diff(diff),
        .borrow(borrow)
    );

endmodule

// Generate and Propagate signals generator
module gp_generator (
    input [3:0] a,
    input [3:0] b,
    output [3:0] g,
    output [3:0] p
);
    assign g = a & ~b;  // Generate
    assign p = a ^ b;   // Propagate
endmodule

// Level 1 computation
module level1_compute (
    input [3:0] g,
    input [3:0] p,
    output [3:0] g_out,
    output [3:0] p_out
);
    assign g_out[0] = g[0];
    assign p_out[0] = p[0];
    assign g_out[1] = g[1] | (p[1] & g[0]);
    assign p_out[1] = p[1] & p[0];
    assign g_out[2] = g[2] | (p[2] & g[1]);
    assign p_out[2] = p[2] & p[1];
    assign g_out[3] = g[3] | (p[3] & g[2]);
    assign p_out[3] = p[3] & p[2];
endmodule

// Level 2 computation
module level2_compute (
    input [3:0] g_in,
    input [3:0] p_in,
    output [3:0] g_out,
    output [3:0] p_out
);
    assign g_out[0] = g_in[0];
    assign p_out[0] = p_in[0];
    assign g_out[1] = g_in[1];
    assign p_out[1] = p_in[1];
    assign g_out[2] = g_in[2] | (p_in[2] & g_in[0]);
    assign p_out[2] = p_in[2] & p_in[0];
    assign g_out[3] = g_in[3] | (p_in[3] & g_in[1]);
    assign p_out[3] = p_in[3] & p_in[1];
endmodule

// Level 3 computation
module level3_compute (
    input [3:0] g_in,
    input [3:0] p_in,
    output [3:0] g_out,
    output [3:0] p_out
);
    assign g_out[0] = g_in[0];
    assign p_out[0] = p_in[0];
    assign g_out[1] = g_in[1];
    assign p_out[1] = p_in[1];
    assign g_out[2] = g_in[2];
    assign p_out[2] = p_in[2];
    assign g_out[3] = g_in[3] | (p_in[3] & g_in[0]);
    assign p_out[3] = p_in[3] & p_in[0];
endmodule

// Final computation
module final_compute (
    input [3:0] p,
    input [3:0] g_level3,
    output [3:0] diff,
    output borrow
);
    assign borrow = g_level3[3];
    assign diff[0] = p[0];
    assign diff[1] = p[1] ^ g_level3[0];
    assign diff[2] = p[2] ^ g_level3[1];
    assign diff[3] = p[3] ^ g_level3[2];
endmodule