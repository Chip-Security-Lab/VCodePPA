module and_gate(
    input b, c,
    output y
);
    assign y = b & c;
endmodule

module mux(
    input d, b, c,
    output y
);
    assign y = d ? ~b : c;
endmodule

module or_gate(
    input a, b_and_c,
    output y
);
    assign y = a | b_and_c;
endmodule

module xor_gate(
    input a, b,
    output y
);
    assign y = a ^ b;
endmodule

module complex_expr(
    input a, b, c, d,
    output y
);
    wire b_and_c;
    wire mux_out;
    wire or_out;

    and_gate u_and(.b(b), .c(c), .y(b_and_c));
    mux u_mux(.d(d), .b(b), .c(c), .y(mux_out));
    or_gate u_or(.a(a), .b_and_c(b_and_c), .y(or_out));
    xor_gate u_xor(.a(or_out), .b(mux_out), .y(y));
endmodule