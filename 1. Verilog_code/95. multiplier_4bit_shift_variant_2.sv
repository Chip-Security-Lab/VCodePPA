//SystemVerilog
module multiplier_4bit_shift (
    input [3:0] a,
    input [3:0] b,
    output [7:0] product
);
    // Intermediate signals for partial products
    wire [7:0] partial_products [3:0];
    wire [7:0] sum_stage1 [1:0];
    wire [7:0] sum_stage2;
    
    // Generate partial products with simplified logic
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_partial
            // Simplified partial product generation
            assign partial_products[i] = (b[i]) ? (a << i) : 8'b0;
        end
    endgenerate
    
    // First stage of carry-save addition
    carry_save_adder csa1 (
        .a(partial_products[0]),
        .b(partial_products[1]),
        .c(partial_products[2]),
        .sum(sum_stage1[0]),
        .carry(sum_stage1[1])
    );
    
    // Second stage of carry-save addition
    carry_save_adder csa2 (
        .a(sum_stage1[0]),
        .b(sum_stage1[1]),
        .c(partial_products[3]),
        .sum(sum_stage2),
        .carry(product)
    );
endmodule

module carry_save_adder (
    input [7:0] a,
    input [7:0] b,
    input [7:0] c,
    output [7:0] sum,
    output [7:0] carry
);
    // Intermediate signals for full adder array
    wire [7:0] temp_sum;
    wire [7:0] temp_carry;
    
    // Full adder array with optimized implementation
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_fa
            full_adder fa (
                .a(a[i]),
                .b(b[i]),
                .cin(c[i]),
                .sum(temp_sum[i]),
                .cout(temp_carry[i])
            );
        end
    endgenerate
    
    // Simplified output assignments
    assign sum = temp_sum;
    assign carry = {temp_carry[6:0], 1'b0};
endmodule

module full_adder (
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    // Intermediate signals for better readability and optimization
    wire a_xor_b;
    wire a_and_b;
    wire cin_and_xor;
    
    // Decomposed logic for better synthesis
    assign a_xor_b = a ^ b;
    assign a_and_b = a & b;
    assign cin_and_xor = cin & a_xor_b;
    
    // Simplified output logic
    assign sum = a_xor_b ^ cin;
    assign cout = a_and_b | cin_and_xor;
endmodule