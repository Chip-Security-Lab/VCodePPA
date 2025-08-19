module nand3_2 (input wire X, input wire Y, input wire Z, output wire F);
    assign F = ~(X & Y & Z);  // Negation of AND operation on three inputs
endmodule