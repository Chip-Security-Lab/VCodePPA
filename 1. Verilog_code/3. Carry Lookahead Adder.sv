module carry_lookahead_adder (
    input  [3:0] a, b,
    output [3:0] sum,
    output       carry
);
    wire [3:0] p, g, c;
    assign p = a ^ b;
    assign g = a & b;

    assign c[0] = g[0] | (p[0] & 0);
    assign c[1] = g[1] | (p[1] & c[0]);
    assign c[2] = g[2] | (p[2] & c[1]);
    assign c[3] = g[3] | (p[3] & c[2]);

    assign sum = p ^ c;
    assign carry = c[3];
endmodule