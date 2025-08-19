//SystemVerilog
// Top-level module: CascadeNor
module CascadeNor (
    input  wire a,
    input  wire b,
    input  wire c,
    output wire y1,
    output wire y2
);
    // Intermediate signal for first NOR stage output
    wire nor1_out;

    // First NOR stage: computes y1 = ~a & ~b
    Nor2Stage u_nor2_stage (
        .in1(a),
        .in2(b),
        .nor_out(nor1_out)
    );

    assign y1 = nor1_out;

    // Second NOR stage: computes y2 = y1 & ~c = ~a & ~b & ~c
    AndNotStage u_andnot_stage (
        .in1(nor1_out),
        .in2(c),
        .andnot_out(y2)
    );

endmodule

// Submodule: Nor2Stage
// Function: 2-input NOR implemented as (~in1 & ~in2)
module Nor2Stage (
    input  wire in1,
    input  wire in2,
    output wire nor_out
);
    assign nor_out = ~in1 & ~in2;
endmodule

// Submodule: AndNotStage
// Function: 2-input AND-NOT, output = in1 & ~in2
module AndNotStage (
    input  wire in1,
    input  wire in2,
    output wire andnot_out
);
    assign andnot_out = in1 & ~in2;
endmodule