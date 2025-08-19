module carry_lookahead_adder (
    input  [3:0] a, b,
    output [3:0] sum,
    output       carry
);
    wire [4:0] p, g;     // Propagate and generate signals
    wire [4:0] c;        // Carry signals
    wire [4:0] a_ext, b_ext;
    
    // Extend inputs to 5-bit
    input_extender u_input_extender (
        .a(a),
        .b(b),
        .a_ext(a_ext),
        .b_ext(b_ext)
    );
    
    // Generate propagate and generate signals
    pg_generator u_pg_generator (
        .a(a_ext),
        .b(b_ext),
        .p(p),
        .g(g)
    );
    
    // Brent-Kung carry lookahead tree
    carry_tree u_carry_tree (
        .p(p),
        .g(g),
        .c(c)
    );
    
    // Sum computation
    sum_calculator u_sum_calculator (
        .p(p[3:0]),
        .c(c[3:0]),
        .sum(sum)
    );
    
    // Final carry output
    assign carry = c[4];
endmodule

module input_extender (
    input  [3:0] a, b,
    output [4:0] a_ext, b_ext
);
    // Extend inputs with zero padding
    assign a_ext = {1'b0, a};
    assign b_ext = {1'b0, b};
endmodule

module pg_generator (
    input  [4:0] a, b,
    output [4:0] p, g
);
    // Calculate propagate and generate signals
    assign p = a ^ b;  // Propagate: XOR of inputs
    assign g = a & b;  // Generate: AND of inputs
endmodule

module carry_tree (
    input  [4:0] p, g,
    output [4:0] c
);
    // First level: Generate (G[i:i-1], P[i:i-1]) pairs
    wire [4:1] g_l1, p_l1;
    
    // Second level: Generate (G[i:i-2], P[i:i-2]) pairs
    wire [4:2] g_l2, p_l2;
    
    // Third level: Generate (G[4:0])
    wire g_l3;
    
    // Level 1 computation
    level1_pg_calc u_level1 (
        .p(p),
        .g(g),
        .g_l1(g_l1),
        .p_l1(p_l1)
    );
    
    // Level 2 computation
    level2_pg_calc u_level2 (
        .g_l1(g_l1),
        .p_l1(p_l1),
        .g_l2(g_l2),
        .p_l2(p_l2)
    );
    
    // Level 3 computation
    assign g_l3 = g_l2[4] | (p_l2[4] & g_l1[1]);
    
    // Carry calculation
    assign c[0] = 1'b0;  // Initial carry-in
    assign c[1] = g[0];
    assign c[2] = g_l1[1];
    assign c[3] = g_l2[2];
    assign c[4] = g_l3;
endmodule

module level1_pg_calc (
    input  [4:0] p, g,
    output [4:1] g_l1, p_l1
);
    // Level 1 PG calculation
    generate
        genvar i;
        for (i = 1; i <= 4; i = i + 1) begin: gen_level1
            assign g_l1[i] = g[i] | (p[i] & g[i-1]);
            assign p_l1[i] = p[i] & p[i-1];
        end
    endgenerate
endmodule

module level2_pg_calc (
    input  [4:1] g_l1, p_l1,
    output [4:2] g_l2, p_l2
);
    // Level 2 PG calculation
    generate
        genvar i;
        for (i = 2; i <= 4; i = i + 2) begin: gen_level2
            assign g_l2[i] = g_l1[i] | (p_l1[i] & g_l1[i-2]);
            assign p_l2[i] = p_l1[i] & p_l1[i-2];
        end
    endgenerate
endmodule

module sum_calculator (
    input  [3:0] p, c,
    output [3:0] sum
);
    // Calculate final sum
    assign sum = p ^ c;
endmodule