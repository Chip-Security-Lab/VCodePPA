//SystemVerilog
// Top-level module: TripleInputOR
module TripleInputOR(
    input  wire a,
    input  wire b,
    input  wire c,
    output wire out
);

    wire or_ab;
    wire and_ac;
    wire final_or;

    // Submodule: OR2 - 2-input OR gate for a and b
    OR2 u_or2_ab (
        .in1 (a),
        .in2 (b),
        .out (or_ab)
    );

    // Submodule: AND2 - 2-input AND gate for a and c
    AND2 u_and2_ac (
        .in1 (a),
        .in2 (c),
        .out (and_ac)
    );

    // Submodule: OR2 - 2-input OR gate for previous results
    OR2 u_or2_final (
        .in1 (or_ab),
        .in2 (and_ac),
        .out (final_or)
    );

    assign out = final_or;

endmodule

// -----------------------------------------------------------------------------
// Submodule: OR2
// 2-input OR gate
// -----------------------------------------------------------------------------
module OR2(
    input  wire in1,
    input  wire in2,
    output wire out
);
    assign out = in1 | in2;
endmodule

// -----------------------------------------------------------------------------
// Submodule: AND2
// 2-input AND gate
// -----------------------------------------------------------------------------
module AND2(
    input  wire in1,
    input  wire in2,
    output wire out
);
    assign out = in1 & in2;
endmodule