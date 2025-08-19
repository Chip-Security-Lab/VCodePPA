module gate_level_adder (
    input  [3:0] a, b,
    output [3:0] sum,
    output       carry
);
    wire [3:0] p, g, c;
    xor (p[0], a[0], b[0]);
    xor (p[1], a[1], b[1]);
    xor (p[2], a[2], b[2]);
    xor (p[3], a[3], b[3]);

    and (g[0], a[0], b[0]);
    and (g[1], a[1], b[1]);
    and (g[2], a[2], b[2]);
    and (g[3], a[3], b[3]);

    or (c[0], g[0], 1'b0);
    or (c[1], g[1], p[1] & c[0]);
    or (c[2], g[2], p[2] & c[1]);
    or (c[3], g[3], p[3] & c[2]);

    xor (sum[0], p[0], 1'b0);
    xor (sum[1], p[1], c[0]);
    xor (sum[2], p[2], c[1]);
    xor (sum[3], p[3], c[2]);

    assign carry = c[3];
endmodule