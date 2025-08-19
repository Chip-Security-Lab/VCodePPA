//SystemVerilog
module PartialProduct(
    input [3:0] a,
    input b_bit,
    input [1:0] shift,
    output [7:0] product
);
    wire [7:0] shifted_a;
    assign shifted_a = {4'b0, a} << shift;
    assign product = b_bit ? shifted_a : 8'b0;
endmodule

module ParallelPrefixAdder(
    input [7:0] pp0, pp1, pp2, pp3,
    output [7:0] sum
);
    // Generate and propagate signals
    wire [7:0] g0, p0, g1, p1, g2, p2, g3, p3;
    wire [7:0] g01, p01, g23, p23;
    wire [7:0] g0123, p0123;
    wire [7:0] carry;
    
    // First level: Generate and propagate for each input
    assign g0 = pp0;
    assign p0 = 8'b0;
    
    assign g1 = pp1;
    assign p1 = 8'b0;
    
    assign g2 = pp2;
    assign p2 = 8'b0;
    
    assign g3 = pp3;
    assign p3 = 8'b0;
    
    // Second level: Combine pairs
    assign g01 = g1 | (p1 & g0);
    assign p01 = p1 & p0;
    
    assign g23 = g3 | (p3 & g2);
    assign p23 = p3 & p2;
    
    // Third level: Combine all
    assign g0123 = g23 | (p23 & g01);
    assign p0123 = p23 & p01;
    
    // Calculate carries
    assign carry[0] = 1'b0;
    assign carry[1] = g0[0];
    assign carry[2] = g01[1] | (p01[1] & carry[1]);
    assign carry[3] = g01[2] | (p01[2] & carry[2]);
    assign carry[4] = g01[3] | (p01[3] & carry[3]);
    assign carry[5] = g01[4] | (p01[4] & carry[4]);
    assign carry[6] = g01[5] | (p01[5] & carry[5]);
    assign carry[7] = g01[6] | (p01[6] & carry[6]);
    
    // Calculate sum
    assign sum = {pp0[7:1], pp0[0]} ^ {pp1[7:1], pp1[0]} ^ {pp2[7:1], pp2[0]} ^ {pp3[7:1], pp3[0]} ^ carry;
endmodule

module Multiplier4(
    input [3:0] a, b,
    output [7:0] result
);
    wire [7:0] pp0, pp1, pp2, pp3;
    
    PartialProduct pp0_inst(
        .a(a),
        .b_bit(b[0]),
        .shift(2'd0),
        .product(pp0)
    );
    
    PartialProduct pp1_inst(
        .a(a),
        .b_bit(b[1]),
        .shift(2'd1),
        .product(pp1)
    );
    
    PartialProduct pp2_inst(
        .a(a),
        .b_bit(b[2]),
        .shift(2'd2),
        .product(pp2)
    );
    
    PartialProduct pp3_inst(
        .a(a),
        .b_bit(b[3]),
        .shift(2'd3),
        .product(pp3)
    );
    
    ParallelPrefixAdder adder_inst(
        .pp0(pp0),
        .pp1(pp1),
        .pp2(pp2),
        .pp3(pp3),
        .sum(result)
    );
endmodule