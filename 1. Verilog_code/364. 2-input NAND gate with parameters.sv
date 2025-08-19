module nand2_7 #(parameter WIDTH = 1) (input wire [WIDTH-1:0] A, input wire [WIDTH-1:0] B, output wire [WIDTH-1:0] Y);
    assign Y = ~(A & B);  // Parameterized width for inputs and output
endmodule
