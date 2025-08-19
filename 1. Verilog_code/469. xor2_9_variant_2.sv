//SystemVerilog
module xor2_9 (
    input wire A, B,
    output wire Y
);
    // Optimize by removing unnecessary shifts that could cost extra resources
    // This maintains functional equivalence while improving efficiency
    assign Y = A ^ B;
endmodule