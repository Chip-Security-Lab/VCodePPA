module nand2_17 #(
    parameter WIDTH = 8
) (
    input wire [WIDTH-1:0] A, B,
    output wire [WIDTH-1:0] Y
);
    assign Y = ~(A & B); // Bitwise NAND operation
endmodule
