module nand3_3 (input wire A, input wire B, input wire C, output reg Y);
    always @ (A or B or C)
        Y = ~(A & B & C);  // NAND of three inputs using always block
endmodule