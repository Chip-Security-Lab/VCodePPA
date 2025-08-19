module nand2_11 (
    input wire A, B,
    output wire Y
);
    // Instantiate the lower-level NAND gate module
    nand2_gate u_nand2_gate (
        .A(A),
        .B(B),
        .Y(Y)
    );
endmodule

module nand2_gate (
    input wire A, B,
    output wire Y
);
    assign Y = ~(A & B);
endmodule
