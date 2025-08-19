module nand2_9 (input wire [3:0] A, input wire [3:0] B, output wire [3:0] Y);
    assign Y = ~(A & B);  // 4-bit wide inputs and output
endmodule