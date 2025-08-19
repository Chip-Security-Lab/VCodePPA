module nand2_1 (input wire A, input wire B, output wire Y);
    assign Y = ~(A & B);  // NAND operation
endmodule