//SystemVerilog
module xor_generate(
    input  [3:0] a, 
    input  [3:0] b, 
    output [3:0] y
);
    // Internal signals
    wire [3:0] p, g;          // Propagate and generate signals
    wire [3:0] p_lvl1, g_lvl1; // Level 1 signals
    wire [3:0] p_lvl2, g_lvl2; // Level 2 signals
    wire [3:0] c;             // Carry signals

    // Step 1: Generate propagate and generate signals
    pg_generator pg_gen_inst (
        .a(a),
        .b(b),
        .p(p),
        .g(g)
    );
    
    // Step 2: Compute prefix levels
    prefix_level1 prefix_l1_inst (
        .p_in(p),
        .g_in(g),
        .p_out(p_lvl1),
        .g_out(g_lvl1)
    );
    
    prefix_level2 prefix_l2_inst (
        .p_in(p_lvl1),
        .g_in(g_lvl1),
        .p_out(p_lvl2),
        .g_out(g_lvl2)
    );
    
    // Step 3: Compute carries
    carry_generator carry_gen_inst (
        .g_in(g_lvl2),
        .c(c)
    );
    
    // Step 4: Compute sum (XOR output)
    sum_calculator sum_calc_inst (
        .p(p),
        .c(c),
        .y(y)
    );
endmodule

// Module for generating propagate and generate signals
module pg_generator(
    input  [3:0] a,
    input  [3:0] b,
    output [3:0] p,
    output [3:0] g
);
    // Propagate = a XOR b
    assign p = a ^ b;
    // Generate = a AND b
    assign g = a & b;
endmodule

// First level of prefix computation
module prefix_level1(
    input  [3:0] p_in,
    input  [3:0] g_in,
    output [3:0] p_out,
    output [3:0] g_out
);
    // Bit 0
    assign p_out[0] = p_in[0];
    assign g_out[0] = g_in[0];
    
    // Bit 1
    assign p_out[1] = p_in[1] & p_in[0];
    assign g_out[1] = g_in[1] | (p_in[1] & g_in[0]);
    
    // Bit 2
    assign p_out[2] = p_in[2];
    assign g_out[2] = g_in[2];
    
    // Bit 3
    assign p_out[3] = p_in[3];
    assign g_out[3] = g_in[3];
endmodule

// Second level of prefix computation
module prefix_level2(
    input  [3:0] p_in,
    input  [3:0] g_in,
    output [3:0] p_out,
    output [3:0] g_out
);
    // Bit 0
    assign p_out[0] = p_in[0];
    assign g_out[0] = g_in[0];
    
    // Bit 1
    assign p_out[1] = p_in[1];
    assign g_out[1] = g_in[1];
    
    // Bit 2
    assign p_out[2] = p_in[2] & p_in[1];
    assign g_out[2] = g_in[2] | (p_in[2] & g_in[1]);
    
    // Bit 3
    assign p_out[3] = p_in[3] & p_in[2] & p_in[1];
    assign g_out[3] = g_in[3] | (p_in[3] & g_in[2]) | (p_in[3] & p_in[2] & g_in[1]);
endmodule

// Carry generation module
module carry_generator(
    input  [3:0] g_in,
    output [3:0] c
);
    assign c[0] = 1'b0;     // Initial carry is 0
    assign c[1] = g_in[0];
    assign c[2] = g_in[1];
    assign c[3] = g_in[2];
endmodule

// Sum calculation module
module sum_calculator(
    input  [3:0] p,
    input  [3:0] c,
    output [3:0] y
);
    assign y = p ^ {c[3:1], 1'b0};
endmodule