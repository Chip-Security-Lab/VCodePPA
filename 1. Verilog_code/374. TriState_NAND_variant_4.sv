//SystemVerilog
// Top-level module
module TriState_NAND (
    input        en,
    input  [3:0] a, b,
    output [3:0] y
);
    // Internal connections
    wire [3:0] nand_result;
    
    // Instantiate logic operation submodule
    NAND_Logic u_nand_logic (
        .in_a          (a),
        .in_b          (b),
        .nand_out      (nand_result)
    );
    
    // Instantiate tristate buffer submodule
    TriState_Buffer u_tristate_buffer (
        .enable        (en),
        .data_in       (nand_result),
        .data_out      (y)
    );
endmodule

// Submodule for NAND logic operation
module NAND_Logic (
    input  [3:0] in_a,
    input  [3:0] in_b,
    output [3:0] nand_out
);
    // Optimized NAND implementation
    assign nand_out = ~(in_a & in_b);
endmodule

// Submodule for tristate buffer functionality
module TriState_Buffer (
    input        enable,
    input  [3:0] data_in,
    output [3:0] data_out
);
    // Tristate buffer implementation
    assign data_out = enable ? data_in : 4'bzzzz;
endmodule