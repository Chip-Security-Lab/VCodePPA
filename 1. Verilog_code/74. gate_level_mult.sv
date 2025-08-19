module gate_level_mult (
    input [1:0] a, b,
    output [3:0] p
);
    wire p1, p2, p3, c1;
    
    and(p[0], a[0], b[0]);
    and(p1, a[1], b[0]);
    and(p2, a[0], b[1]);
    and(p3, a[1], b[1]);
    
    half_adder ha1(p1, p2, p[1], c1);
    half_adder ha2(p3, c1, p[2], p[3]);
endmodule

module half_adder (
    input a, b,
    output sum, cout
);
    xor(sum, a, b);
    and(cout, a, b);
endmodule