//SystemVerilog
// Top-level module
module multiplier_8bit_step (
    input [7:0] a,
    input [7:0] b,
    output [15:0] product
);

    wire [7:0] partial_products [7:0];
    wire [15:0] sum_tree [3:0];
    wire [15:0] sum_tree2 [1:0];
    
    // Partial product generation
    partial_product_gen pp_gen (
        .a(a),
        .b(b),
        .partial_products(partial_products)
    );
    
    // First level addition
    first_level_adder first_level (
        .partial_products(partial_products),
        .sum_tree(sum_tree)
    );
    
    // Second level addition
    second_level_adder second_level (
        .sum_tree(sum_tree),
        .sum_tree2(sum_tree2)
    );
    
    // Final addition
    adder_16bit final_adder (
        .a(sum_tree2[0]),
        .b(sum_tree2[1]),
        .sum(product)
    );

endmodule

// Partial product generation module
module partial_product_gen (
    input [7:0] a,
    input [7:0] b,
    output [7:0] partial_products [7:0]
);

    genvar i, j;
    generate
        for(i = 0; i < 8; i = i + 1) begin : gen_partial_products
            for(j = 0; j < 8; j = j + 1) begin : gen_pp
                assign partial_products[i][j] = a[i] & b[j];
            end
        end
    endgenerate

endmodule

// First level addition module
module first_level_adder (
    input [7:0] partial_products [7:0],
    output [15:0] sum_tree [3:0]
);

    genvar i;
    generate
        for(i = 0; i < 4; i = i + 1) begin : gen_first_level
            adder_4bit adder_inst (
                .a({partial_products[2*i], 8'b0}),
                .b({8'b0, partial_products[2*i+1]}),
                .sum(sum_tree[i])
            );
        end
    endgenerate

endmodule

// Second level addition module
module second_level_adder (
    input [15:0] sum_tree [3:0],
    output [15:0] sum_tree2 [1:0]
);

    genvar i;
    generate
        for(i = 0; i < 2; i = i + 1) begin : gen_second_level
            adder_8bit adder_inst (
                .a(sum_tree[2*i]),
                .b(sum_tree[2*i+1]),
                .sum(sum_tree2[i])
            );
        end
    endgenerate

endmodule

// Adder modules
module adder_4bit (
    input [11:0] a,
    input [11:0] b,
    output [15:0] sum
);
    assign sum = a + b;
endmodule

module adder_8bit (
    input [15:0] a,
    input [15:0] b,
    output [15:0] sum
);
    assign sum = a + b;
endmodule

module adder_16bit (
    input [15:0] a,
    input [15:0] b,
    output [15:0] sum
);
    assign sum = a + b;
endmodule