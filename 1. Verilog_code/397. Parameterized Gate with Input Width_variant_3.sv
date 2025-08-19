//SystemVerilog
module nand2_17 #(
    parameter WIDTH = 8
) (
    input wire [WIDTH-1:0] A, B,
    output wire [WIDTH-1:0] Y
);
    // Optimized implementation
    // The original code computes ~(A - B & A - B)
    // Since ~(X & X) = ~X, this simplifies to ~(A - B)
    // And A - B = A + (~B + 1)
    
    // Direct implementation of ~(A - B)
    assign Y = ~(A + ~B + 1'b1);
    
endmodule