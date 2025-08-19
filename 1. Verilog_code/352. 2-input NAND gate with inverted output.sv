module nand2_2 (input wire A, input wire B, output wire Y);
    assign Y = ~(A & B);  // Output is the negation of the AND of inputs A and B
endmodule
