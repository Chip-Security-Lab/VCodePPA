//SystemVerilog
// Top-level module: 8-bit Brent-Kung Adder

module brent_kung_adder_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire cin,
    output wire [7:0] sum,
    output wire cout
);
    wire [7:0] p, g;   // Propagate and generate signals
    wire [7:0] c;      // Carry signals
    
    // Instantiate the PG generator module
    pg_generator pg_gen_inst (
        .a(a),
        .b(b),
        .p(p),
        .g(g)
    );
    
    // Instantiate the Brent-Kung tree module
    brent_kung_tree bk_tree_inst (
        .p(p),
        .g(g),
        .cin(cin),
        .c(c),
        .cout(cout)
    );
    
    // Instantiate the sum calculator module
    sum_calculator sum_calc_inst (
        .p(p),
        .c(c),
        .sum(sum)
    );
endmodule

// Module for generating propagate and generate signals
module pg_generator (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] p,
    output wire [7:0] g
);
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : pg_gen
            assign p[i] = a[i] ^ b[i];
            assign g[i] = a[i] & b[i];
        end
    endgenerate
endmodule

// Module for computing sum from propagate and carry signals
module sum_calculator (
    input wire [7:0] p,
    input wire [7:0] c,
    output wire [7:0] sum
);
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : sum_gen
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate
endmodule

// Module for Brent-Kung carry generation tree
module brent_kung_tree (
    input wire [7:0] p,
    input wire [7:0] g,
    input wire cin,
    output wire [7:0] c,
    output wire cout
);
    // Stage 2: Level 1 groups (pairs)
    wire [3:0] p_st2, g_st2;
    
    // Stage 3: Level 2 groups (groups of 4)
    wire [1:0] p_st3, g_st3;
    
    // Stage 4: Level 3 group (group of 8)
    wire p_st4, g_st4;
    
    // Instantiate the group PG calculator for level 1
    level1_pg_calc l1_pg_inst (
        .p(p),
        .g(g),
        .p_out(p_st2),
        .g_out(g_st2)
    );
    
    // Instantiate the group PG calculator for level 2
    level2_pg_calc l2_pg_inst (
        .p_in(p_st2),
        .g_in(g_st2),
        .p_out(p_st3),
        .g_out(g_st3)
    );
    
    // Instantiate the group PG calculator for level 3
    level3_pg_calc l3_pg_inst (
        .p_in(p_st3),
        .g_in(g_st3),
        .p_out(p_st4),
        .g_out(g_st4)
    );
    
    // Instantiate the carry generator
    carry_generator carry_gen_inst (
        .p(p),
        .g(g),
        .p_st2(p_st2),
        .g_st2(g_st2),
        .p_st3(p_st3),
        .g_st3(g_st3),
        .p_st4(p_st4),
        .g_st4(g_st4),
        .cin(cin),
        .c(c),
        .cout(cout)
    );
endmodule

// Module for level 1 group PG calculation (pairs)
module level1_pg_calc (
    input wire [7:0] p,
    input wire [7:0] g,
    output wire [3:0] p_out,
    output wire [3:0] g_out
);
    // Create pairs of PG signals (level 1)
    assign p_out[0] = p[1] & p[0];
    assign g_out[0] = g[1] | (p[1] & g[0]);
    
    assign p_out[1] = p[3] & p[2];
    assign g_out[1] = g[3] | (p[3] & g[2]);
    
    assign p_out[2] = p[5] & p[4];
    assign g_out[2] = g[5] | (p[5] & g[4]);
    
    assign p_out[3] = p[7] & p[6];
    assign g_out[3] = g[7] | (p[7] & g[6]);
endmodule

// Module for level 2 group PG calculation (groups of 4)
module level2_pg_calc (
    input wire [3:0] p_in,
    input wire [3:0] g_in,
    output wire [1:0] p_out,
    output wire [1:0] g_out
);
    // Create groups of 4 PG signals (level 2)
    assign p_out[0] = p_in[1] & p_in[0];
    assign g_out[0] = g_in[1] | (p_in[1] & g_in[0]);
    
    assign p_out[1] = p_in[3] & p_in[2];
    assign g_out[1] = g_in[3] | (p_in[3] & g_in[2]);
endmodule

// Module for level 3 group PG calculation (group of 8)
module level3_pg_calc (
    input wire [1:0] p_in,
    input wire [1:0] g_in,
    output wire p_out,
    output wire g_out
);
    // Create group of 8 PG signals (level 3)
    assign p_out = p_in[1] & p_in[0];
    assign g_out = g_in[1] | (p_in[1] & g_in[0]);
endmodule

// Module for generating all carries using inverse Brent-Kung tree
module carry_generator (
    input wire [7:0] p,
    input wire [7:0] g,
    input wire [3:0] p_st2,
    input wire [3:0] g_st2,
    input wire [1:0] p_st3,
    input wire [1:0] g_st3,
    input wire p_st4,
    input wire g_st4,
    input wire cin,
    output wire [7:0] c,
    output wire cout
);
    // Calculate all carries using inverse Brent-Kung tree
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g_st2[0] | (p_st2[0] & cin);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g_st3[0] | (p_st3[0] & cin);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g_st2[2] | (p_st2[2] & c[4]);
    assign c[7] = g[6] | (p[6] & c[6]);
    assign cout = g_st4 | (p_st4 & cin);
endmodule

// Basic AND gate module (preserved from original)
module and_gate_generate (
    input wire a,  // Input A
    input wire b,  // Input B
    output wire y  // Output Y
);
    // For compatibility with original interface, compute AND while maintaining
    // the same input/output ports as the original module
    assign y = a & b;
endmodule