// Top level module
module kogge_stone_adder (
    input  [3:0] a, b,
    output [3:0] sum,
    output       carry
);

    wire [3:0] p, g;
    wire [3:0] g1, p1;
    wire [3:0] g2, p2; 
    wire [3:0] g3, p3;

    // Generate and propagate module
    gp_generator gp_gen (
        .a(a),
        .b(b),
        .p(p),
        .g(g)
    );

    // Stage 1 module
    stage1 stage1_inst (
        .p(p),
        .g(g),
        .g1(g1),
        .p1(p1)
    );

    // Stage 2 module  
    stage2 stage2_inst (
        .g1(g1),
        .p1(p1),
        .g2(g2),
        .p2(p2)
    );

    // Stage 3 module
    stage3 stage3_inst (
        .g2(g2),
        .p2(p2),
        .g3(g3),
        .p3(p3)
    );

    // Final sum and carry module
    sum_carry_gen sum_carry_inst (
        .p(p),
        .g3(g3),
        .sum(sum),
        .carry(carry)
    );

endmodule

// Generate and propagate module
module gp_generator (
    input  [3:0] a, b,
    output [3:0] p, g
);
    assign p = a ^ b;
    assign g = a & b;
endmodule

// Stage 1 module
module stage1 (
    input  [3:0] p, g,
    output [3:0] g1, p1
);
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];
    
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[3] = p[3] & p[2];
endmodule

// Stage 2 module
module stage2 (
    input  [3:0] g1, p1,
    output [3:0] g2, p2
);
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];
endmodule

// Stage 3 module
module stage3 (
    input  [3:0] g2, p2,
    output [3:0] g3, p3
);
    assign g3[0] = g2[0];
    assign p3[0] = p2[0];
    
    assign g3[1] = g2[1];
    assign p3[1] = p2[1];
    
    assign g3[2] = g2[2];
    assign p3[2] = p2[2];
    
    assign g3[3] = g2[3] | (p2[3] & g2[0]);
    assign p3[3] = p2[3] & p2[0];
endmodule

// Final sum and carry module
module sum_carry_gen (
    input  [3:0] p, g3,
    output [3:0] sum,
    output       carry
);
    assign sum[0] = p[0];
    assign sum[1] = p[1] ^ g3[0];
    assign sum[2] = p[2] ^ g3[1];
    assign sum[3] = p[3] ^ g3[2];
    assign carry = g3[3];
endmodule