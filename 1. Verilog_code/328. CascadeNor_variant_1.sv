//SystemVerilog
// Top-level module: CascadeNor
module CascadeNor(
    input  wire a,
    input  wire b,
    input  wire c,
    output wire y1,
    output wire y2
);

    wire ab_nor_out;

    // Submodule: Nor2
    // Function: 2-input NOR logic, used for y1
    Nor2 u_nor2 (
        .in1(a),
        .in2(b),
        .out(ab_nor_out)
    );
    assign y1 = ab_nor_out;

    // Submodule: Nor3
    // Function: 3-input NOR logic, used for y2
    Nor3 u_nor3 (
        .in1(a),
        .in2(b),
        .in3(c),
        .out(y2)
    );

endmodule

// Nor2: 2-input NOR gate submodule
module Nor2(
    input  wire in1,
    input  wire in2,
    output wire out
);
    assign out = (~in1) & (~in2);
endmodule

// Nor3: 3-input NOR-equivalent logic submodule
module Nor3(
    input  wire in1,
    input  wire in2,
    input  wire in3,
    output wire out
);
    assign out = (~in1) & (~in2) & (~in3);
endmodule