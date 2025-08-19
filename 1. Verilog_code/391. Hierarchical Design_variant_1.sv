//SystemVerilog
module nand_gate_top (
    input wire A, B,
    output wire Y_standard,
    output wire Y_demorgan
);
    // Top-level module instantiating specialized sub-modules
    
    // Standard NAND implementation
    nand_standard_impl standard_nand (
        .A(A),
        .B(B),
        .Y(Y_standard)
    );
    
    // DeMorgan's implementation
    nand_demorgan_impl demorgan_nand (
        .A(A),
        .B(B),
        .Y(Y_demorgan)
    );
endmodule

module nand_standard_impl (
    input wire A, B,
    output wire Y
);
    // Direct implementation optimized for timing and area
    // Implementation using standard AND-NOT approach
    assign Y = ~(A & B);
endmodule

module nand_demorgan_impl (
    input wire A, B,
    output wire Y
);
    // Implementation using De Morgan's law
    // Provides synthesis flexibility and potential for different PPA characteristics
    assign Y = (~A) | (~B);
endmodule