//SystemVerilog
// Partial Product Generation Module
module partial_product_gen (
    input [1:0] a,
    input [1:0] b,
    output [3:0] partial_products
);
    assign partial_products[0] = a[0] & b[0];
    assign partial_products[1] = a[1] & b[0];
    assign partial_products[2] = a[0] & b[1];
    assign partial_products[3] = a[1] & b[1];
endmodule

// Carry Lookahead Logic Module
module carry_lookahead (
    input [3:0] partial_products,
    output [3:0] g,
    output [3:0] p_carry,
    output [3:0] c
);
    assign g[0] = partial_products[1] & partial_products[2];
    assign p_carry[0] = partial_products[1] ^ partial_products[2];
    
    assign g[1] = partial_products[3] & p_carry[0];
    assign p_carry[1] = partial_products[3] ^ p_carry[0];
    
    assign c[0] = g[0];
    assign c[1] = g[1] | (p_carry[1] & c[0]);
endmodule

// Sum Generation Module
module sum_gen (
    input [3:0] p_carry,
    input [3:0] c,
    output [1:0] sum
);
    assign sum[0] = p_carry[0];
    assign sum[1] = p_carry[1] ^ c[0];
endmodule

// Top Level Multiplier Module
module gate_level_mult (
    input [1:0] a,
    input [1:0] b,
    output reg [3:0] p
);
    wire [3:0] partial_products;
    wire [3:0] g, p_carry, c;
    wire [1:0] sum;

    partial_product_gen pp_gen (
        .a(a),
        .b(b),
        .partial_products(partial_products)
    );

    carry_lookahead cla (
        .partial_products(partial_products),
        .g(g),
        .p_carry(p_carry),
        .c(c)
    );

    sum_gen sg (
        .p_carry(p_carry),
        .c(c),
        .sum(sum)
    );

    always @(*) begin
        p[0] = partial_products[0];
        p[1] = sum[0];
        p[2] = sum[1];
        p[3] = c[1];
    end
endmodule