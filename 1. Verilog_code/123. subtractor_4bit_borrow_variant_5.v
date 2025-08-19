// 顶层模块
module subtractor_4bit_borrow (
    input [3:0] a,
    input [3:0] b, 
    output [3:0] diff,
    output borrow
);

    wire [3:0] b_inv;
    wire [3:0] b_comp;
    wire [3:0] sum;
    wire carry;

    complement_generator comp_gen (
        .b(b),
        .b_inv(b_inv)
    );

    carry_lookahead_adder_4bit add (
        .a(a),
        .b(b_comp),
        .cin(1'b1),
        .sum(sum),
        .cout(carry)
    );

    assign b_comp = b_inv;
    assign diff = sum;
    assign borrow = ~carry;

endmodule

module complement_generator (
    input [3:0] b,
    output [3:0] b_inv
);
    assign b_inv = ~b;
endmodule

module carry_lookahead_adder_4bit (
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout
);

    wire [3:0] p;
    wire [3:0] g;
    wire [3:0] c;

    // Generate and Propagate
    assign p = a ^ b;
    assign g = a & b;

    // Carry Lookahead Logic
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
    assign cout = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin);

    // Sum Generation
    assign sum = p ^ c;

endmodule