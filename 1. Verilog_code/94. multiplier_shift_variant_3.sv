//SystemVerilog
// Top-level module
module multiplier_shift (
    input [7:0] a,
    input [7:0] b,
    output [15:0] product
);

    wire [15:0] partial_products [7:0];
    wire [15:0] sum_stage1 [3:0];
    wire [15:0] sum_stage2 [1:0];
    wire [15:0] final_sum;

    // Partial product generation module
    partial_product_gen pp_gen (
        .a(a),
        .b(b),
        .partial_products(partial_products)
    );

    // First stage addition module
    adder_stage1 stage1 (
        .partial_products(partial_products),
        .sum_stage1(sum_stage1)
    );

    // Second stage addition module
    adder_stage2 stage2 (
        .sum_stage1(sum_stage1),
        .sum_stage2(sum_stage2)
    );

    // Final addition module
    final_adder fin_adder (
        .sum_stage2(sum_stage2),
        .final_sum(final_sum)
    );

    assign product = final_sum;

endmodule

// Partial product generation module
module partial_product_gen (
    input [7:0] a,
    input [7:0] b,
    output [15:0] partial_products [7:0]
);

    genvar i;
    generate
        for(i = 0; i < 8; i = i + 1) begin : partial_product_gen
            assign partial_products[i] = b[i] ? (a << i) : 16'b0;
        end
    endgenerate

endmodule

// First stage addition module
module adder_stage1 (
    input [15:0] partial_products [7:0],
    output [15:0] sum_stage1 [3:0]
);

    adder_16bit adder_stage1_0 (
        .a(partial_products[0]),
        .b(partial_products[1]),
        .sum(sum_stage1[0])
    );

    adder_16bit adder_stage1_1 (
        .a(partial_products[2]),
        .b(partial_products[3]),
        .sum(sum_stage1[1])
    );

    adder_16bit adder_stage1_2 (
        .a(partial_products[4]),
        .b(partial_products[5]),
        .sum(sum_stage1[2])
    );

    adder_16bit adder_stage1_3 (
        .a(partial_products[6]),
        .b(partial_products[7]),
        .sum(sum_stage1[3])
    );

endmodule

// Second stage addition module
module adder_stage2 (
    input [15:0] sum_stage1 [3:0],
    output [15:0] sum_stage2 [1:0]
);

    adder_16bit adder_stage2_0 (
        .a(sum_stage1[0]),
        .b(sum_stage1[1]),
        .sum(sum_stage2[0])
    );

    adder_16bit adder_stage2_1 (
        .a(sum_stage1[2]),
        .b(sum_stage1[3]),
        .sum(sum_stage2[1])
    );

endmodule

// Final addition module
module final_adder (
    input [15:0] sum_stage2 [1:0],
    output [15:0] final_sum
);

    adder_16bit final_adder (
        .a(sum_stage2[0]),
        .b(sum_stage2[1]),
        .sum(final_sum)
    );

endmodule

// 16-bit adder module
module adder_16bit (
    input [15:0] a,
    input [15:0] b,
    output [15:0] sum
);
    assign sum = a + b;
endmodule