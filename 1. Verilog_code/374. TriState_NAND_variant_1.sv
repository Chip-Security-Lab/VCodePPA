//SystemVerilog
// Top-level module
module TriState_NAND(
    input en,
    input [3:0] a, b,
    output [3:0] y
);
    // Internal signals
    wire [3:0] nand_result;
    
    // Instantiate NAND operation submodule
    NAND_Operator nand_op (
        .a(a),
        .b(b),
        .result(nand_result)
    );
    
    // Instantiate tri-state buffer submodule
    TriState_Buffer tri_buf (
        .en(en),
        .data_in(nand_result),
        .data_out(y)
    );
endmodule

// Submodule for NAND operation
module NAND_Operator(
    input [3:0] a,
    input [3:0] b,
    output [3:0] result
);
    // Optimized NAND operation
    assign result = ~(a & b);
endmodule

// Submodule for tri-state buffer
module TriState_Buffer(
    input en,
    input [3:0] data_in,
    output [3:0] data_out
);
    // Tri-state buffer implementation
    assign data_out = en ? data_in : 4'bzzzz;
endmodule