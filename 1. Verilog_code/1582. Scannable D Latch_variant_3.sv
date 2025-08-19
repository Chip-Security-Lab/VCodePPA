//SystemVerilog
// Top level module
module baugh_wooley_multiplier (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [15:0] product
);

    wire [7:0] a_ext;
    wire [7:0] b_ext;
    wire [7:0][7:0] partial_products;
    wire [7:0][7:0] pp_sign_ext;
    wire [15:0] sum;
    wire [15:0] carry;

    // Input extension module
    input_extension u_input_ext (
        .a(a),
        .b(b),
        .a_ext(a_ext),
        .b_ext(b_ext)
    );

    // Partial product generation module  
    partial_product_gen u_pp_gen (
        .a_ext(a_ext),
        .b_ext(b_ext),
        .partial_products(partial_products)
    );

    // Sign extension module
    sign_extension u_sign_ext (
        .partial_products(partial_products),
        .pp_sign_ext(pp_sign_ext)
    );

    // Wallace tree reduction module
    wallace_tree u_wallace_tree (
        .pp_sign_ext(pp_sign_ext),
        .sum(sum),
        .carry(carry)
    );

    // Final addition
    assign product = sum + carry;

endmodule

// Input extension module
module input_extension (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] a_ext,
    output wire [7:0] b_ext
);
    assign a_ext = {a[7], a};
    assign b_ext = {b[7], b};
endmodule

// Partial product generation module
module partial_product_gen (
    input wire [7:0] a_ext,
    input wire [7:0] b_ext,
    output wire [7:0][7:0] partial_products
);
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : pp_gen
            for (j = 0; j < 8; j = j + 1) begin : pp_row
                assign partial_products[i][j] = a_ext[i] & b_ext[j];
            end
        end
    endgenerate
endmodule

// Sign extension module
module sign_extension (
    input wire [7:0][7:0] partial_products,
    output wire [7:0][7:0] pp_sign_ext
);
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : sign_ext
            for (j = 0; j < 8; j = j + 1) begin : sign_row
                assign pp_sign_ext[i][j] = (i == 7 && j == 7) ? ~partial_products[i][j] : partial_products[i][j];
            end
        end
    endgenerate
endmodule

// Wallace tree reduction module
module wallace_tree (
    input wire [7:0][7:0] pp_sign_ext,
    output wire [15:0] sum,
    output wire [15:0] carry
);
    wire [7:0][7:0] sum1;
    wire [7:0][7:0] carry1;
    wire [7:0][7:0] sum2;
    wire [7:0][7:0] carry2;

    // First level compression
    // ... existing code ...

    // Second level compression
    // ... existing code ...

    // Final addition
    assign {carry, sum} = sum2 + carry2;
endmodule