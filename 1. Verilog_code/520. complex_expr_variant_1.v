module and_gate(
    input b, c,
    output temp1
);
    assign temp1 = b & c;
endmodule

module or_gate(
    input a, temp1,
    output temp2
);
    assign temp2 = a | temp1;
endmodule

module mux_gate(
    input d, b, c,
    output temp3
);
    assign temp3 = d ? ~b : c;
endmodule

module xor_gate(
    input temp2, temp3,
    output y
);
    assign y = temp2 ^ temp3;
endmodule

module complex_expr(
    input a, b, c, d,
    output y
);
    wire temp1, temp2, temp3;
    
    and_gate u_and(
        .b(b),
        .c(c),
        .temp1(temp1)
    );
    
    or_gate u_or(
        .a(a),
        .temp1(temp1),
        .temp2(temp2)
    );
    
    mux_gate u_mux(
        .d(d),
        .b(b),
        .c(c),
        .temp3(temp3)
    );
    
    xor_gate u_xor(
        .temp2(temp2),
        .temp3(temp3),
        .y(y)
    );
endmodule