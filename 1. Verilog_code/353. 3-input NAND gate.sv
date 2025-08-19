module nand3_1 (input wire A, input wire B, input wire C, output wire Y);
    assign Y = ~(A & B & C);  // NAND of three inputs
endmodule