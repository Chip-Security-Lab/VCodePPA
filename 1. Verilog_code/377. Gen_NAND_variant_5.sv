//SystemVerilog
// Top-level module: 16-bit vector-wise NAND gate with hierarchical structure
module Gen_NAND(
    input  [15:0] vec_a,
    input  [15:0] vec_b,
    output [15:0] result
);
    // Lower 8 bits NAND operation
    Gen_NAND8 u_nand8_low (
        .a(vec_a[7:0]),
        .b(vec_b[7:0]),
        .nand_out(result[7:0])
    );

    // Upper 8 bits NAND operation
    Gen_NAND8 u_nand8_high (
        .a(vec_a[15:8]),
        .b(vec_b[15:8]),
        .nand_out(result[15:8])
    );
endmodule

// Submodule: 8-bit vector-wise NAND gate
// Performs bitwise NAND between two 8-bit vectors
module Gen_NAND8(
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] nand_out
);
    // Bitwise NAND operation for 8 bits
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_nand
            assign nand_out[i] = ~(a[i] & b[i]);
        end
    endgenerate
endmodule