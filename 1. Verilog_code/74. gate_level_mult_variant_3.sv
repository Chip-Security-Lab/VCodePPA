//SystemVerilog
// Partial product generation module
module partial_product_gen (
    input [1:0] a, b,
    output [3:0] partial_products
);
    and(partial_products[0], a[0], b[0]);
    and(partial_products[1], a[1], b[0]);
    and(partial_products[2], a[0], b[1]);
    and(partial_products[3], a[1], b[1]);
endmodule

// Brent-Kung adder module
module brent_kung_adder (
    input [3:0] partial_products,
    output [3:0] sum,
    output carry_out
);
    wire [3:0] g, p_bk;
    wire [2:0] c;
    
    // Generate and Propagate signals
    and(g[0], partial_products[1], partial_products[2]);
    xor(p_bk[0], partial_products[1], partial_products[2]);
    
    // First level carry computation
    and(g[1], partial_products[3], p_bk[0]);
    or(g[2], g[0], g[1]);
    and(p_bk[1], partial_products[3], p_bk[0]);
    
    // Second level carry computation
    and(g[3], g[2], p_bk[1]);
    or(c[2], g[2], g[3]);
    
    // Sum computation
    xor(sum[0], partial_products[0], 1'b0);
    xor(sum[1], p_bk[0], 1'b0);
    xor(sum[2], partial_products[3], c[2]);
    assign sum[3] = c[2];
    assign carry_out = c[2];
endmodule

// Top-level multiplier module
module gate_level_mult (
    input [1:0] a, b,
    output [3:0] p
);
    wire [3:0] partial_products;
    wire carry_out;
    
    // Instantiate partial product generation module
    partial_product_gen pp_gen (
        .a(a),
        .b(b),
        .partial_products(partial_products)
    );
    
    // Instantiate Brent-Kung adder module
    brent_kung_adder bk_adder (
        .partial_products(partial_products),
        .sum(p),
        .carry_out(carry_out)
    );
endmodule