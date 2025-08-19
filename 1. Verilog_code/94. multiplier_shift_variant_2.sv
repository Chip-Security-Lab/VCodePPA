//SystemVerilog
module multiplier_shift (
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] product
);

    wire [15:0] partial_products [7:0];
    wire [15:0] sum_stage1 [3:0];
    wire [15:0] sum_stage2 [1:0];
    
    // Generate partial products with optimized logic
    genvar i;
    generate
        for(i = 0; i < 8; i = i + 1) begin : gen_partial
            assign partial_products[i] = {8'b0, a} & {16{b[i]}};
        end
    endgenerate

    // First stage of carry-save addition with optimized CSA
    carry_save_adder_opt csa1_0 (
        .a(partial_products[0]),
        .b(partial_products[1]),
        .c(partial_products[2]),
        .sum(sum_stage1[0]),
        .carry(sum_stage1[1])
    );

    carry_save_adder_opt csa1_1 (
        .a(partial_products[3]),
        .b(partial_products[4]),
        .c(partial_products[5]),
        .sum(sum_stage1[2]),
        .carry(sum_stage1[3])
    );

    // Second stage of carry-save addition
    carry_save_adder_opt csa2_0 (
        .a(sum_stage1[0]),
        .b(sum_stage1[1]),
        .c(sum_stage1[2]),
        .sum(sum_stage2[0]),
        .carry(sum_stage2[1])
    );

    // Final addition with optimized logic
    wire [15:0] final_sum;
    wire [15:0] final_carry;
    
    assign final_sum = sum_stage2[0] ^ sum_stage2[1] ^ partial_products[6] ^ partial_products[7];
    assign final_carry = ((sum_stage2[0] & sum_stage2[1]) | 
                         (sum_stage2[0] & partial_products[6]) | 
                         (sum_stage2[0] & partial_products[7]) |
                         (sum_stage2[1] & partial_products[6]) |
                         (sum_stage2[1] & partial_products[7]) |
                         (partial_products[6] & partial_products[7])) << 1;

    always @(*) begin
        product = final_sum + final_carry;
    end

endmodule

module carry_save_adder_opt (
    input [15:0] a,
    input [15:0] b,
    input [15:0] c,
    output [15:0] sum,
    output [15:0] carry
);

    // Optimized carry-save adder using simplified boolean expressions
    assign sum = a ^ b ^ c;
    assign carry = ((a & b) | (a & c) | (b & c)) << 1;

endmodule