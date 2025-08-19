//SystemVerilog
// Top-level module: float_lerp
// Function: Floating-point linear interpolation with parameterized mantissa and exponent widths

module float_lerp #(
    parameter MANT = 10,
    parameter EXP  = 5
)(
    input  wire [MANT+EXP:0] a,
    input  wire [MANT+EXP:0] b,
    input  wire [7:0]        t,
    output wire [MANT+EXP:0] c
);

    // Internal signals for intermediate results
    wire [MANT+EXP+8:0]      weighted_a;
    wire [MANT+EXP+8:0]      weighted_b;
    wire [MANT*2+1:0]        sum_prod;

    // Submodule: WeightedMultiplier
    WeightedMultiplier #(
        .WIDTH(MANT+EXP+1)
    ) weighted_a_mult (
        .x(a),
        .scale(8'd256 - t),
        .product(weighted_a)
    );

    WeightedMultiplier #(
        .WIDTH(MANT+EXP+1)
    ) weighted_b_mult (
        .x(b),
        .scale(t),
        .product(weighted_b)
    );

    // Submodule: ProductAdder (uses Han-Carlson 8-bit adder)
    ProductAdder #(
        .WIDTH(MANT+EXP+9)
    ) prod_adder (
        .in0(weighted_a),
        .in1(weighted_b),
        .sum(sum_prod)
    );

    // Submodule: RightShifter
    RightShifter #(
        .IN_WIDTH(MANT*2+2),
        .OUT_WIDTH(MANT+EXP+1),
        .SHIFT(8)
    ) right_shifter (
        .in(sum_prod),
        .out(c)
    );

endmodule

// Submodule: WeightedMultiplier
// Function: Multiplies input x by an 8-bit scale factor
module WeightedMultiplier #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] x,
    input  wire [7:0]       scale,
    output wire [WIDTH+8-1:0] product
);
    assign product = x * scale;
endmodule

// Submodule: ProductAdder
// Function: Adds two input values of the same width using Han-Carlson 8-bit adder for lower 8 bits
module ProductAdder #(
    parameter WIDTH = 24
)(
    input  wire [WIDTH-1:0] in0,
    input  wire [WIDTH-1:0] in1,
    output wire [WIDTH:0]   sum
);
    wire [7:0] sum_lower;
    wire       carry_out_lower;
    wire [WIDTH-8:0] upper_sum;
    wire [WIDTH-8:0] upper_in0;
    wire [WIDTH-8:0] upper_in1;

    assign upper_in0 = in0[WIDTH-1:8];
    assign upper_in1 = in1[WIDTH-1:8];

    HanCarlsonAdder8 han_carlson_adder_inst (
        .a(in0[7:0]),
        .b(in1[7:0]),
        .cin(1'b0),
        .sum(sum_lower),
        .cout(carry_out_lower)
    );

    assign upper_sum = upper_in0 + upper_in1 + carry_out_lower;

    assign sum = {upper_sum, sum_lower};
endmodule

// Han-Carlson 8-bit adder module
module HanCarlsonAdder8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       cin,
    output wire [7:0] sum,
    output wire       cout
);
    wire [7:0] g, p;
    wire [7:0] c;

    // Generate and propagate
    assign g = a & b;
    assign p = a ^ b;

    // Han-Carlson prefix carry computation
    // Stage 0 (input)
    wire [7:0] g0 = g;
    wire [7:0] p0 = p;

    // Stage 1
    wire [7:0] g1, p1;
    assign g1[0] = g0[0];
    assign p1[0] = p0[0];
    assign g1[1] = g0[1] | (p0[1] & g0[0]);
    assign p1[1] = p0[1] & p0[0];
    assign g1[2] = g0[2];
    assign p1[2] = p0[2];
    assign g1[3] = g0[3] | (p0[3] & g0[2]);
    assign p1[3] = p0[3] & p0[2];
    assign g1[4] = g0[4];
    assign p1[4] = p0[4];
    assign g1[5] = g0[5] | (p0[5] & g0[4]);
    assign p1[5] = p0[5] & p0[4];
    assign g1[6] = g0[6];
    assign p1[6] = p0[6];
    assign g1[7] = g0[7] | (p0[7] & g0[6]);
    assign p1[7] = p0[7] & p0[6];

    // Stage 2
    wire [7:0] g2, p2;
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];
    assign g2[4] = g1[4];
    assign p2[4] = p1[4];
    assign g2[5] = g1[5];
    assign p2[5] = p1[5];
    assign g2[6] = g1[6] | (p1[6] & g1[4]);
    assign p2[6] = p1[6] & p1[4];
    assign g2[7] = g1[7] | (p1[7] & g1[5]);
    assign p2[7] = p1[7] & p1[5];

    // Stage 3
    wire [7:0] g3;
    assign g3[0] = g2[0];
    assign g3[1] = g2[1];
    assign g3[2] = g2[2];
    assign g3[3] = g2[3];
    assign g3[4] = g2[4] | (p2[4] & g2[0]);
    assign g3[5] = g2[5] | (p2[5] & g2[1]);
    assign g3[6] = g2[6] | (p2[6] & g2[2]);
    assign g3[7] = g2[7] | (p2[7] & g2[3]);

    // Carry computation
    assign c[0] = cin;
    assign c[1] = g0[0] | (p0[0] & cin);
    assign c[2] = g1[1] | (p1[1] & cin);
    assign c[3] = g2[2] | (p2[2] & cin);
    assign c[4] = g3[3] | (p2[3] & cin);
    assign c[5] = g3[4] | (p2[4] & cin);
    assign c[6] = g3[5] | (p2[5] & cin);
    assign c[7] = g3[6] | (p2[6] & cin);

    // Sum and final carry-out
    assign sum = p ^ c;
    assign cout = g3[7] | (p2[7] & cin);
endmodule

// Submodule: RightShifter
// Function: Shifts input right by a parameterized amount
module RightShifter #(
    parameter IN_WIDTH  = 24,
    parameter OUT_WIDTH = 16,
    parameter SHIFT     = 8
)(
    input  wire [IN_WIDTH-1:0] in,
    output wire [OUT_WIDTH-1:0] out
);
    assign out = in[IN_WIDTH-1:SHIFT];
endmodule