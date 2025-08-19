module nor2_reversed (
    input wire A, B,
    output wire Y
);
    wire nA, nB;
    not (nA, A);  // Generate inverted signals
    not (nB, B);
    
    // Standard NOR operation on original inputs
    assign Y = ~(A | B);
endmodule