//SystemVerilog
// Top-level module: IterNorHier
module IterNorHier(
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] y
);
    wire [7:0] nor_result;
    wire [7:0] sum;
    wire       carry_out;

    // Instance: Bitwise NOR Generator
    Nor8Bit u_nor8bit (
        .a(a),
        .b(b),
        .nor_out(nor_result)
    );

    // Instance: 8-bit Carry Lookahead Adder
    CarryLookaheadAdder8 u_cla8 (
        .a(a),
        .b(b),
        .cin(1'b0),
        .sum(sum),
        .cout(carry_out)
    );

    // Output assignment
    assign y = nor_result;
endmodule

//------------------------------------------------------------------------------
// Submodule: Nor8Bit
// Function: Performs bitwise NOR operation on two 8-bit input vectors.
//------------------------------------------------------------------------------
module Nor8Bit(
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] nor_out
);
    assign nor_out = ~(a | b);
endmodule

//------------------------------------------------------------------------------
// Submodule: CarryLookaheadAdder8
// Function: 8-bit Carry Lookahead Adder for fast addition.
//------------------------------------------------------------------------------
module CarryLookaheadAdder8(
    input  [7:0] a,
    input  [7:0] b,
    input        cin,
    output [7:0] sum,
    output       cout
);
    wire [7:0] p;    // propagate
    wire [7:0] g;    // generate
    wire [8:0] c;    // carry

    assign p = a ^ b;
    assign g = a & b;

    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[8] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);

    assign sum = p ^ c[7:0];
    assign cout = c[8];
endmodule