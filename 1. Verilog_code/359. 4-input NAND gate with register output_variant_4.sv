//SystemVerilog
// Top-level module for 4-input NAND gate with hierarchical structure
module nand4_3 (
    input  wire A,
    input  wire B,
    input  wire C,
    input  wire D,
    output wire Y
);

    wire nand_ab_out;
    wire nand_cd_out;

    // 2-input NAND for A and B
    nand2 u_nand2_ab (
        .in1(A),
        .in2(B),
        .y(nand_ab_out)
    );

    // 2-input NAND for C and D
    nand2 u_nand2_cd (
        .in1(C),
        .in2(D),
        .y(nand_cd_out)
    );

    // Final 2-input NAND for previous outputs
    nand2 u_nand2_final (
        .in1(nand_ab_out),
        .in2(nand_cd_out),
        .y(Y)
    );

endmodule

//-----------------------------------------------------------------------------
// 2-input NAND gate submodule
//-----------------------------------------------------------------------------
module nand2 (
    input  wire in1,
    input  wire in2,
    output wire y
);
    assign y = ~(in1 & in2);
endmodule