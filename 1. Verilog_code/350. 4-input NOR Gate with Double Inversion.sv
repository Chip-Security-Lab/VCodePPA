module nor4_double_invert (
    input wire A, B, C, D,
    output wire Y
);
    wire n1;
    assign n1 = ~(A | B | C | D);  // NOR operation
    assign Y = n1;  // Direct assignment, removing second inversion
endmodule