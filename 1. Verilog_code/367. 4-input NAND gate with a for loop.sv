module nand4_4 (input wire [3:0] A, input wire [3:0] B, input wire [3:0] C, input wire [3:0] D, output wire [3:0] Y);
    assign Y = ~(A & B & C & D);  // NAND operation using array-style inputs
endmodule