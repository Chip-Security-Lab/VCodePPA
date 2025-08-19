module and_gate(
    input a, b,
    output y
);
    assign y = a & b;
endmodule

module or_gate(
    input a, b,
    output y
);
    assign y = a | b;
endmodule

module ao_logic(
    input a, b, c, d,
    output y
);
    wire and1_out, and2_out;
    
    and_gate and1(
        .a(a),
        .b(b),
        .y(and1_out)
    );
    
    and_gate and2(
        .a(c),
        .b(d),
        .y(and2_out)
    );
    
    or_gate or1(
        .a(and1_out),
        .b(and2_out),
        .y(y)
    );
endmodule