module nand4_1 (input wire A, input wire B, input wire C, input wire D, output wire Y);
    assign Y = ~(A & B & C & D);  // Four-input NAND operation
endmodule