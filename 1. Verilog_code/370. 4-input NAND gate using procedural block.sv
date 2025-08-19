module nand4_6 (input wire A, input wire B, input wire C, input wire D, output reg Y);
    always @ (A or B or C or D)
        Y = ~(A & B & C & D);  // Procedural block implementation of 4-input NAND gate
endmodule