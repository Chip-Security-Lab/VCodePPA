module nand2_3 (input wire A, input wire B, output reg Y);
    always @ (A or B)
        Y = ~(A & B);  // NAND operation using always block
endmodule