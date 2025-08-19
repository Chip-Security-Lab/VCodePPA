module han_carlson_adder(
    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output cout
);

    // Generate and propagate signals
    wire [3:0] g = a & b;
    wire [3:0] p = a ^ b;
    
    // Han-Carlson carry computation
    wire [3:0] c;
    wire [3:0] carry_terms;
    
    // First level - parallel prefix computation
    wire [1:0] g_01 = g[1] | (p[1] & g[0]);
    wire [1:0] p_01 = p[1] & p[0];
    wire [1:0] g_23 = g[3] | (p[3] & g[2]);
    wire [1:0] p_23 = p[3] & p[2];
    
    // Second level - parallel prefix computation
    wire [3:0] g_final;
    wire [3:0] p_final;
    
    assign g_final[0] = g[0];
    assign p_final[0] = p[0];
    assign g_final[1] = g_01;
    assign p_final[1] = p_01;
    assign g_final[2] = g[2] | (p[2] & g_01);
    assign p_final[2] = p[2] & p_01;
    assign g_final[3] = g_23 | (p_23 & g_01);
    assign p_final[3] = p_23 & p_01;
    
    // Final carry computation
    assign carry_terms[0] = g_final[0] | (p_final[0] & cin);
    assign carry_terms[1] = g_final[1] | (p_final[1] & cin);
    assign carry_terms[2] = g_final[2] | (p_final[2] & cin);
    assign carry_terms[3] = g_final[3] | (p_final[3] & cin);
    
    // Final sum computation
    assign c = {carry_terms[3:1], cin};
    assign sum = p ^ c;
    assign cout = carry_terms[3];

endmodule