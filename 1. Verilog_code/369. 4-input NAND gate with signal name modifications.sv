module nand4_5 (input wire A1, input wire B1, input wire C1, input wire D1, output wire Y);
    assign Y = ~(A1 & B1 & C1 & D1);  // Four-input NAND gate with custom names
endmodule