module nand2_15 (
    input wire A, B,
    output wire Y
);
    wire and_out;

    // Perform proper NAND operation
    and (and_out, A, B);  // First AND the inputs
    not (Y, and_out);     // Then NOT the result
endmodule