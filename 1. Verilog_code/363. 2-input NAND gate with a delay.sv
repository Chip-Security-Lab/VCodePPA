module nand2_6 (input wire A, input wire B, output wire Y);
    assign #10 Y = ~(A & B);  // Introduce a delay of 10 time units
endmodule