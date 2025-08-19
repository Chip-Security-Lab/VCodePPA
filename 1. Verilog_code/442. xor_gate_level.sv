module xor_gate_level(input a, b, output y);
    wire w1, w2, not_a, not_b;
    not (not_a, a);
    not (not_b, b);
    and (w1, a, not_b);
    and (w2, not_a, b);
    or  (y, w1, w2);
endmodule