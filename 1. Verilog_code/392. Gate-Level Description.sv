module nand2_12 (
    input wire A, B,
    output wire Y
);
    wire and_out;
    wire not_out;

    // Implementing NAND using basic AND and NOT gates
    and (and_out, A, B);
    not (not_out, and_out);
    assign Y = not_out;
endmodule
