module nand2_8 (input wire A, input wire B, output wire Y);
    assign Y = ~(A & B);  // Corrected implementation for a proper NAND gate
endmodule