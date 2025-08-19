module nor2_param (
    input wire [1:0] A,  // Input bit width can be parameterized
    input wire [1:0] B,
    output wire [1:0] Y  // Output should match input width
);
    // Perform NOR operation bitwise
    assign Y[0] = ~(A[0] | B[0]);
    assign Y[1] = ~(A[1] | B[1]);
endmodule