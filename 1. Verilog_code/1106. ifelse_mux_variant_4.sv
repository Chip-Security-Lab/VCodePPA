//SystemVerilog

// Top-level Mux and Multiply Unit
module ifelse_mux (
    input wire control,                   // Control signal
    input wire [3:0] path_a, path_b,      // Data paths
    output wire [7:0] selected            // Output data path (8 bits for multiplication result)
);

    // Intermediate signals for multiplication results
    wire [7:0] result_a;
    wire [7:0] result_b;

    // Instantiate Multiplier for path_a * path_b
    mul4x4_unit mul_unit_a (
        .multiplicand(path_a),
        .multiplier(path_b),
        .product(result_a)
    );

    // Instantiate Multiplier for path_b * path_a
    mul4x4_unit mul_unit_b (
        .multiplicand(path_b),
        .multiplier(path_a),
        .product(result_b)
    );

    // Instantiate 2:1 Mux for selecting the result
    mux2to1_8bit mux_unit (
        .sel(control),
        .in0(result_a),
        .in1(result_b),
        .out(selected)
    );

endmodule

// 4x4 Wallace Tree Multiplier Wrapper
// Instantiates partial product generator and Wallace reduction
module mul4x4_unit (
    input  wire [3:0] multiplicand,
    input  wire [3:0] multiplier,
    output wire [7:0] product
);
    wire [3:0] pp0, pp1, pp2, pp3;
    wire [7:0] pp0_ext, pp1_ext, pp2_ext, pp3_ext;
    wire [7:0] sum_s1, carry_c1, sum_s2, carry_c2;

    // Partial Product Generation
    partial_product_gen_4bit pp_gen (
        .multiplicand(multiplicand),
        .multiplier(multiplier),
        .pp0(pp0),
        .pp1(pp1),
        .pp2(pp2),
        .pp3(pp3)
    );

    // Partial Product Alignment
    partial_product_align_4bit pp_align (
        .pp0(pp0),
        .pp1(pp1),
        .pp2(pp2),
        .pp3(pp3),
        .pp0_ext(pp0_ext),
        .pp1_ext(pp1_ext),
        .pp2_ext(pp2_ext),
        .pp3_ext(pp3_ext)
    );

    // Wallace Tree Reduction
    wallace_tree_reduction_4bit wallace_reduce (
        .pp0_ext(pp0_ext),
        .pp1_ext(pp1_ext),
        .pp2_ext(pp2_ext),
        .pp3_ext(pp3_ext),
        .sum_s1(sum_s1),
        .carry_c1(carry_c1),
        .sum_s2(sum_s2),
        .carry_c2(carry_c2)
    );

    // Final Addition
    assign product = sum_s2 + (carry_c2 << 1);

endmodule

// Partial Product Generator for 4x4 Multiplication
// Generates 4 partial products based on multiplier bits
module partial_product_gen_4bit (
    input  wire [3:0] multiplicand,
    input  wire [3:0] multiplier,
    output wire [3:0] pp0,
    output wire [3:0] pp1,
    output wire [3:0] pp2,
    output wire [3:0] pp3
);
    assign pp0 = multiplier[0] ? multiplicand : 4'b0;
    assign pp1 = multiplier[1] ? multiplicand : 4'b0;
    assign pp2 = multiplier[2] ? multiplicand : 4'b0;
    assign pp3 = multiplier[3] ? multiplicand : 4'b0;
endmodule

// Partial Product Alignment for 4x4 Multiplication
// Shifts partial products to align their significance
module partial_product_align_4bit (
    input  wire [3:0] pp0,
    input  wire [3:0] pp1,
    input  wire [3:0] pp2,
    input  wire [3:0] pp3,
    output wire [7:0] pp0_ext,
    output wire [7:0] pp1_ext,
    output wire [7:0] pp2_ext,
    output wire [7:0] pp3_ext
);
    assign pp0_ext = {4'b0, pp0};
    assign pp1_ext = {3'b0, pp1, 1'b0};
    assign pp2_ext = {2'b0, pp2, 2'b0};
    assign pp3_ext = {1'b0, pp3, 3'b0};
endmodule

// Wallace Tree Reduction for 4x4 Multiplier
// Reduces aligned partial products to two rows (sum and carry)
module wallace_tree_reduction_4bit (
    input  wire [7:0] pp0_ext,
    input  wire [7:0] pp1_ext,
    input  wire [7:0] pp2_ext,
    input  wire [7:0] pp3_ext,
    output wire [7:0] sum_s1,
    output wire [7:0] carry_c1,
    output wire [7:0] sum_s2,
    output wire [7:0] carry_c2
);
    // First reduction stage
    assign sum_s1[0] = pp0_ext[0];
    assign carry_c1[0] = 1'b0;
    assign {carry_c1[1], sum_s1[1]} = pp0_ext[1] + pp1_ext[1];
    assign {carry_c1[2], sum_s1[2]} = pp0_ext[2] + pp1_ext[2] + pp2_ext[2];
    assign {carry_c1[3], sum_s1[3]} = pp0_ext[3] + pp1_ext[3] + pp2_ext[3];
    assign {carry_c1[4], sum_s1[4]} = pp0_ext[4] + pp1_ext[4] + pp2_ext[4];
    assign {carry_c1[5], sum_s1[5]} = pp0_ext[5] + pp1_ext[5] + pp2_ext[5];
    assign {carry_c1[6], sum_s1[6]} = pp0_ext[6] + pp1_ext[6] + pp2_ext[6];
    assign {carry_c1[7], sum_s1[7]} = pp0_ext[7] + pp1_ext[7] + pp2_ext[7];

    // Second reduction stage
    assign {carry_c2[0], sum_s2[0]} = {1'b0, sum_s1[0]} + {1'b0, pp3_ext[0]} + {1'b0, 1'b0};
    assign {carry_c2[1], sum_s2[1]} = sum_s1[1] + pp3_ext[1] + carry_c1[1];
    assign {carry_c2[2], sum_s2[2]} = sum_s1[2] + pp3_ext[2] + carry_c1[2];
    assign {carry_c2[3], sum_s2[3]} = sum_s1[3] + pp3_ext[3] + carry_c1[3];
    assign {carry_c2[4], sum_s2[4]} = sum_s1[4] + pp3_ext[4] + carry_c1[4];
    assign {carry_c2[5], sum_s2[5]} = sum_s1[5] + pp3_ext[5] + carry_c1[5];
    assign {carry_c2[6], sum_s2[6]} = sum_s1[6] + pp3_ext[6] + carry_c1[6];
    assign {carry_c2[7], sum_s2[7]} = sum_s1[7] + pp3_ext[7] + carry_c1[7];
endmodule

// 2:1 Multiplexer for 8-bit data
module mux2to1_8bit (
    input  wire sel,
    input  wire [7:0] in0,
    input  wire [7:0] in1,
    output wire [7:0] out
);
    assign out = sel ? in1 : in0;
endmodule