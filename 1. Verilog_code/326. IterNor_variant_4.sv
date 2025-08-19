//SystemVerilog
// Top-level module: IterNorHier
module IterNorHier(
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] y
);

    // Internal signal for NOR operation
    wire [7:0] nor_result;

    // Instantiate the 8-bit NOR logic unit
    Nor8LogicUnit u_nor8_logic_unit (
        .in_a(a),
        .in_b(b),
        .nor_out(nor_result)
    );

    // Output register logic
    OutputRegister u_output_register (
        .data_in(nor_result),
        .data_out(y)
    );

endmodule

// ---------------------------------------------------------------------------
// Nor8LogicUnit: Performs 8-bit bitwise NOR operation
// ---------------------------------------------------------------------------
module Nor8LogicUnit (
    input  [7:0] in_a,
    input  [7:0] in_b,
    output [7:0] nor_out
);
    assign nor_out = ~(in_a | in_b);
endmodule

// ---------------------------------------------------------------------------
// OutputRegister: Latches the input data to output (combinational, for code compatibility)
// ---------------------------------------------------------------------------
module OutputRegister (
    input  [7:0] data_in,
    output [7:0] data_out
);
    assign data_out = data_in;
endmodule