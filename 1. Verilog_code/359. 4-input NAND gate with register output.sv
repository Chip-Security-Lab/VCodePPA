module nand4_3 (input wire A, input wire B, input wire C, input wire D, output reg Y);
    always @ (A or B or C or D)
        Y = ~(A & B & C & D);  // 4-input NAND gate with procedural logic
endmodule