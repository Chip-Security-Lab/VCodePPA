module nand3_4 (input wire [3:0] A, input wire [3:0] B, input wire [3:0] C, output wire [3:0] Y);
    assign Y = ~(A & B & C);  // 4-bit wide 3-input NAND gate
endmodule