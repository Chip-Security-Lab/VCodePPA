module nand2_5 (input wire [7:0] A, input wire [7:0] B, output wire [7:0] Y);
    assign Y = ~(A & B);  // 8-bit wide NAND gate
endmodule