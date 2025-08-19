module xor_bidir(
    inout a,
    inout b,
    inout y
);
    assign y = a ^ b;
endmodule