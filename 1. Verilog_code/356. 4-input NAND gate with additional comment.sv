module nand4_2 (input wire A, input wire B, input wire C, input wire D, output wire Y);
    // This is a 4-input NAND gate
    assign Y = ~(A & B & C & D);  // Negated AND of all four inputs
endmodule