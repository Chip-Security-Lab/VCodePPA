//SystemVerilog
module multiplier_4bit_shift (
    input [3:0] a,
    input [3:0] b,
    output [7:0] product
);
    // Partial products
    wire [7:0] pp0 = b[0] ? {4'b0, a} : 8'b0;
    wire [7:0] pp1 = b[1] ? {3'b0, a, 1'b0} : 8'b0;
    wire [7:0] pp2 = b[2] ? {2'b0, a, 2'b0} : 8'b0;
    wire [7:0] pp3 = b[3] ? {1'b0, a, 3'b0} : 8'b0;

    // Brent-Kung adder implementation
    wire [7:0] sum1, sum2;
    wire [7:0] carry1, carry2;
    
    // First level of Brent-Kung
    brent_kung_adder_4bit bk_adder1 (
        .a(pp0[3:0]),
        .b(pp1[3:0]),
        .cin(1'b0),
        .sum(sum1[3:0]),
        .cout(carry1[0])
    );
    
    brent_kung_adder_4bit bk_adder2 (
        .a(pp2[3:0]),
        .b(pp3[3:0]),
        .cin(1'b0),
        .sum(sum2[3:0]),
        .cout(carry2[0])
    );
    
    // Second level of Brent-Kung
    brent_kung_adder_8bit bk_adder_final (
        .a({4'b0, sum1[3:0]}),
        .b({4'b0, sum2[3:0]}),
        .cin(1'b0),
        .sum(product[7:0]),
        .cout()
    );
endmodule

module brent_kung_adder_4bit (
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [3:0] g, p;
    wire [3:0] c;
    
    // Generate and propagate
    assign g = a & b;
    assign p = a ^ b;
    
    // Carry computation
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign cout = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // Sum computation
    assign sum = p ^ c;
endmodule

module brent_kung_adder_8bit (
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [7:0] g, p;
    wire [7:0] c;
    
    // Generate and propagate
    assign g = a & b;
    assign p = a ^ b;
    
    // Carry computation
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign cout = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // Sum computation
    assign sum = p ^ c;
endmodule