//SystemVerilog
// Top-level NAND4_6 module: Hierarchically structured 4-input NAND gate
module nand4_6 (
    input  wire A,
    input  wire B,
    input  wire C,
    input  wire D,
    output wire Y
);

    // Internal signals for intermediate results
    wire nand_ab_out;
    wire nand_cd_out;

    // Instance: 2-input NAND gate for A and B
    nand2_gate u_nand2_ab (
        .in1(A),
        .in2(B),
        .out(nand_ab_out)
    );

    // Instance: 2-input NAND gate for C and D
    nand2_gate u_nand2_cd (
        .in1(C),
        .in2(D),
        .out(nand_cd_out)
    );

    // Instance: 2-input NAND gate combining previous results
    nand2_gate u_nand2_final (
        .in1(nand_ab_out),
        .in2(nand_cd_out),
        .out(Y)
    );

endmodule

// -----------------------------------------------------------------------------
// 2-input NAND gate submodule
// Function: Produces the NAND of two input signals
// -----------------------------------------------------------------------------
module nand2_gate (
    input  wire in1,
    input  wire in2,
    output wire out
);
    assign out = ~(in1 & in2);
endmodule