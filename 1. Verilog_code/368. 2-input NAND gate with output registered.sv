module nand2_10 (input wire A, input wire B, output reg Y);
    always @ (A, B)
        Y <= ~(A & B);  // Non-blocking assignment for registered output
endmodule