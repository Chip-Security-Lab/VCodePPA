//SystemVerilog
// Top level module
module multiplier_comb (
    input [7:0] a,
    input [7:0] b, 
    output [15:0] product
);

    // Internal signals
    wire [7:0] partial_products [7:0];
    wire [15:0] sum_tree;

    // Generate partial products - unrolled
    assign partial_products[0] = a & {8{b[0]}};
    assign partial_products[1] = a & {8{b[1]}};
    assign partial_products[2] = a & {8{b[2]}};
    assign partial_products[3] = a & {8{b[3]}};
    assign partial_products[4] = a & {8{b[4]}};
    assign partial_products[5] = a & {8{b[5]}};
    assign partial_products[6] = a & {8{b[6]}};
    assign partial_products[7] = a & {8{b[7]}};

    // Instantiate adder tree
    adder_tree u_adder_tree (
        .partial_products(partial_products),
        .sum(sum_tree)
    );

    // Final product assignment
    assign product = sum_tree;

endmodule

// Adder tree module
module adder_tree (
    input [7:0] partial_products [7:0],
    output [15:0] sum
);

    // Internal signals for adder tree
    wire [8:0] level1 [3:0];
    wire [9:0] level2 [1:0];
    wire [10:0] level3;

    // First level of adders - unrolled
    assign level1[0] = partial_products[0] + (partial_products[1] << 1);
    assign level1[1] = partial_products[2] + (partial_products[3] << 1);
    assign level1[2] = partial_products[4] + (partial_products[5] << 1);
    assign level1[3] = partial_products[6] + (partial_products[7] << 1);

    // Second level of adders
    assign level2[0] = level1[0] + (level1[1] << 2);
    assign level2[1] = level1[2] + (level1[3] << 2);

    // Final level
    assign level3 = level2[0] + (level2[1] << 4);

    // Output assignment
    assign sum = level3;

endmodule