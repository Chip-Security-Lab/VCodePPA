//SystemVerilog
// Hierarchical floating-point linear interpolation (refactored)

// Top-level module: Hierarchical floating-point linear interpolation
module float_lerp #(
    parameter MANT = 10,
    parameter EXP = 5
)(
    input  wire [MANT+EXP:0] a,
    input  wire [MANT+EXP:0] b,
    input  wire [7:0]        t,
    output wire [MANT+EXP:0] c
);

    // Weight signals
    wire [7:0] weight_a;
    wire [7:0] weight_b;

    // Multiplier outputs
    wire [MANT+EXP+8:0] mul_a_result;
    wire [MANT+EXP+8:0] mul_b_result;

    // Adder output
    wire [MANT+EXP+9:0] sum_result;

    // Weight Generation Subsystem
    lerp_weight_gen #(
        .WIDTH(8)
    ) u_weight_gen (
        .t_in      (t),
        .weight_a  (weight_a),
        .weight_b  (weight_b)
    );

    // Multiplication Subsystem
    lerp_multiply #(
        .DATA_WIDTH  (MANT+EXP+1),
        .WEIGHT_WIDTH(8)
    ) u_multiply (
        .a        (a),
        .b        (b),
        .weight_a (weight_a),
        .weight_b (weight_b),
        .mul_a    (mul_a_result),
        .mul_b    (mul_b_result)
    );

    // Addition Subsystem
    lerp_add #(
        .WIDTH (MANT+EXP+9+1)
    ) u_add (
        .in0   (mul_a_result),
        .in1   (mul_b_result),
        .sum   (sum_result)
    );

    // Normalization Subsystem
    lerp_normalize #(
        .IN_WIDTH  (MANT+EXP+10),
        .OUT_WIDTH (MANT+EXP+1),
        .SHIFT     (8)
    ) u_normalize (
        .in   (sum_result),
        .out  (c)
    );

endmodule

//------------------------------------------------------------------------------
// Submodule: lerp_weight_gen
// Generates weights for interpolation: weight_a = 256-t, weight_b = t
//------------------------------------------------------------------------------
module lerp_weight_gen #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] t_in,
    output wire [WIDTH-1:0] weight_a,
    output wire [WIDTH-1:0] weight_b
);
    assign weight_a = {1'b1, {WIDTH-1{1'b0}}} - t_in; // 256-t for WIDTH=8
    assign weight_b = t_in;
endmodule

//------------------------------------------------------------------------------
// Submodule: lerp_multiply
// Performs two parallel multiplications: a*weight_a and b*weight_b
//------------------------------------------------------------------------------
module lerp_multiply #(
    parameter DATA_WIDTH = 16,
    parameter WEIGHT_WIDTH = 8
)(
    input  wire [DATA_WIDTH-1:0]  a,
    input  wire [DATA_WIDTH-1:0]  b,
    input  wire [WEIGHT_WIDTH-1:0] weight_a,
    input  wire [WEIGHT_WIDTH-1:0] weight_b,
    output wire [DATA_WIDTH+WEIGHT_WIDTH-1:0] mul_a,
    output wire [DATA_WIDTH+WEIGHT_WIDTH-1:0] mul_b
);
    assign mul_a = a * weight_a;
    assign mul_b = b * weight_b;
endmodule

//------------------------------------------------------------------------------
// Submodule: lerp_add
// Adds two input vectors of equal width
//------------------------------------------------------------------------------
module lerp_add #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0] in0,
    input  wire [WIDTH-1:0] in1,
    output wire [WIDTH-1:0] sum
);
    assign sum = in0 + in1;
endmodule

//------------------------------------------------------------------------------
// Submodule: lerp_normalize
// Performs right shift for normalization (division by 2^SHIFT)
//------------------------------------------------------------------------------
module lerp_normalize #(
    parameter IN_WIDTH = 32,
    parameter OUT_WIDTH = 16,
    parameter SHIFT = 8
)(
    input  wire [IN_WIDTH-1:0] in,
    output wire [OUT_WIDTH-1:0] out
);
    assign out = in[IN_WIDTH-1:SHIFT];
endmodule