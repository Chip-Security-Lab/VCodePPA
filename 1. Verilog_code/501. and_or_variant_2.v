module and_gate (
    input a, b,
    output w1
);
    assign w1 = a & b;
endmodule

module or_gate (
    input c, d,
    output w2
);
    assign w2 = c | d;
endmodule

module xor_gate (
    input w1, w2,
    output y
);
    assign y = w1 ^ w2;
endmodule

module and_or (
    input a, b, c, d,
    output y
);
    wire w1, w2;
    
    and_gate u_and (
        .a(a),
        .b(b),
        .w1(w1)
    );
    
    or_gate u_or (
        .c(c),
        .d(d),
        .w2(w2)
    );
    
    xor_gate u_xor (
        .w1(w1),
        .w2(w2),
        .y(y)
    );
endmodule