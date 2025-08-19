module carry_save_adder (
    input  [3:0] a, b, c,
    output [3:0] sum,
    output [3:0] carry
);

    // Generate and propagate signals
    wire [3:0] g, p;
    assign g = (a & b) | (b & c) | (a & c);
    assign p = a ^ b ^ c;

    // Kogge-Stone prefix tree
    wire [3:0] g1, p1;
    wire [3:0] g2, p2;
    wire [3:0] g3, p3;

    // First level
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[3] = p[3] & p[2];

    // Second level
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];

    // Third level
    assign g3[0] = g2[0];
    assign p3[0] = p2[0];
    assign g3[1] = g2[1];
    assign p3[1] = p2[1];
    assign g3[2] = g2[2];
    assign p3[2] = p2[2];
    assign g3[3] = g2[3] | (p2[3] & g2[0]);
    assign p3[3] = p2[3] & p2[0];

    // Final outputs
    assign sum = p;
    assign carry = g3;

endmodule