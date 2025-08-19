//SystemVerilog
// Top level module
module decoder_dynamic_base (
    input [7:0] base_addr,
    input [7:0] current_addr,
    output sel
);
    // Internal signals
    wire [3:0] base_high_nibble;
    wire [3:0] current_high_nibble;
    wire [7:0] mult_result;
    
    // Instantiate nibble extractor modules
    nibble_extractor #(.POSITION(1)) base_extractor (
        .addr(base_addr),
        .nibble(base_high_nibble)
    );
    
    nibble_extractor #(.POSITION(1)) current_extractor (
        .addr(current_addr),
        .nibble(current_high_nibble)
    );
    
    // Instantiate Baugh-Wooley multiplier instead of comparator
    baugh_wooley_multiplier bw_mult_inst (
        .a(base_high_nibble),
        .b(current_high_nibble),
        .product(mult_result)
    );
    
    // Generate select signal based on multiplication result
    // When nibbles match, XOR will produce all zeros, then OR result will be 0
    assign sel = ~|((base_high_nibble ^ current_high_nibble));
endmodule

// Module to extract a nibble from byte address
module nibble_extractor #(
    parameter POSITION = 1  // 1 for high nibble, 0 for low nibble
)(
    input [7:0] addr,
    output [3:0] nibble
);
    assign nibble = (POSITION == 1) ? addr[7:4] : addr[3:0];
endmodule

// Baugh-Wooley 4x4 bit multiplier implementation
module baugh_wooley_multiplier (
    input [3:0] a,
    input [3:0] b,
    output [7:0] product
);
    // Partial product generation
    wire [3:0][3:0] pp;
    wire [15:0] partial_products;
    
    // Explicitly expanded partial products for rows 0-2
    // Row 0
    assign pp[0][0] = a[0] & b[0];
    assign pp[0][1] = a[0] & b[1];
    assign pp[0][2] = a[0] & b[2];
    assign pp[0][3] = ~(a[0] & b[3]);
    
    // Row 1
    assign pp[1][0] = a[1] & b[0];
    assign pp[1][1] = a[1] & b[1];
    assign pp[1][2] = a[1] & b[2];
    assign pp[1][3] = ~(a[1] & b[3]);
    
    // Row 2
    assign pp[2][0] = a[2] & b[0];
    assign pp[2][1] = a[2] & b[1];
    assign pp[2][2] = a[2] & b[2];
    assign pp[2][3] = ~(a[2] & b[3]);
    
    // Row 3 (last row)
    assign pp[3][0] = ~(a[3] & b[0]);
    assign pp[3][1] = ~(a[3] & b[1]);
    assign pp[3][2] = ~(a[3] & b[2]);
    assign pp[3][3] = a[3] & b[3];
    
    // Flatten partial products for easier handling
    assign partial_products = {pp[3][3], pp[3][2], pp[3][1], pp[3][0],
                              pp[2][3], pp[2][2], pp[2][1], pp[2][0],
                              pp[1][3], pp[1][2], pp[1][1], pp[1][0],
                              pp[0][3], pp[0][2], pp[0][1], pp[0][0]};
    
    // Adder tree for compressing partial products
    wire [7:0] sum_level1_1, sum_level1_2;
    wire [7:0] carry_level1_1, carry_level1_2;
    wire [7:0] final_sum;
    
    // Level 1 compression - split into two groups
    assign sum_level1_1 = {1'b0, partial_products[6], partial_products[4], partial_products[2], partial_products[0], 3'b0};
    assign carry_level1_1 = {partial_products[7], partial_products[5], partial_products[3], partial_products[1], 4'b0};
    
    assign sum_level1_2 = {1'b0, partial_products[14], partial_products[12], partial_products[10], partial_products[8], 3'b0};
    assign carry_level1_2 = {partial_products[15], partial_products[13], partial_products[11], partial_products[9], 4'b0};
    
    // Level 2 - final addition
    // Adding a constant '1' for Baugh-Wooley algorithm
    assign final_sum = sum_level1_1 + carry_level1_1 + sum_level1_2 + carry_level1_2 + 8'b10000000;
    
    // Final output
    assign product = final_sum;
endmodule