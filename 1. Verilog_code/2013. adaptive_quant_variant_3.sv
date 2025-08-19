//SystemVerilog
module adaptive_quant(
    input  [31:0] f,
    input  [7:0]  bits,
    output reg [31:0] q
);
    reg [31:0] scale;
    wire [63:0] wallace_product;
    reg        is_positive;
    reg        is_overflow_pos;
    reg        is_overflow_neg;
    reg [32:0] temp_high;
    reg [32:0] neg_mask;

    wallace_multiplier_32x32 u_wallace_multiplier_32x32 (
        .multiplicand(f),
        .multiplier(scale),
        .product(wallace_product)
    );

    always @(*) begin
        scale = 32'b1 << bits;

        is_positive    = (f[31] == 1'b0);
        temp_high      = wallace_product[63:31];
        neg_mask       = {33{1'b1}};
        is_overflow_pos = is_positive && (temp_high != 33'b0);
        is_overflow_neg = ~is_positive && (temp_high != neg_mask);

        if (is_overflow_pos) begin
            q = 32'h7FFFFFFF;
        end else if (is_overflow_neg) begin
            q = 32'h80000000;
        end else begin
            q = wallace_product[31:0];
        end
    end
endmodule

module wallace_multiplier_32x32 (
    input  [31:0] multiplicand,
    input  [31:0] multiplier,
    output [63:0] product
);
    wire [63:0] partial_products [31:0];
    genvar i;

    // Generate partial products
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_partial_products
            assign partial_products[i] = multiplier[i] ? (multiplicand << i) : 64'b0;
        end
    endgenerate

    // Wallace tree reduction
    wire [63:0] stage1_sum [15:0], stage1_carry [15:0];
    wire [63:0] stage2_sum [7:0],  stage2_carry [7:0];
    wire [63:0] stage3_sum [3:0],  stage3_carry [3:0];
    wire [63:0] stage4_sum [1:0],  stage4_carry [1:0];
    wire [63:0] stage5_sum, stage5_carry;

    // First stage: reduce 32 partial products to 16
    generate
        for (i = 0; i < 16; i = i + 1) begin : stage1
            wallace_full_adder_64 fa1 (
                .a(partial_products[i*2]),
                .b(partial_products[i*2+1]),
                .cin(64'b0),
                .sum(stage1_sum[i]),
                .carry(stage1_carry[i])
            );
        end
    endgenerate

    // Second stage: reduce 16 to 8
    generate
        for (i = 0; i < 8; i = i + 1) begin : stage2
            wallace_full_adder_64 fa2 (
                .a(stage1_sum[i*2]),
                .b(stage1_sum[i*2+1]),
                .cin(stage1_carry[i*2]),
                .sum(stage2_sum[i]),
                .carry(stage2_carry[i])
            );
        end
    endgenerate

    // Third stage: reduce 8 to 4
    generate
        for (i = 0; i < 4; i = i + 1) begin : stage3
            wallace_full_adder_64 fa3 (
                .a(stage2_sum[i*2]),
                .b(stage2_sum[i*2+1]),
                .cin(stage2_carry[i*2]),
                .sum(stage3_sum[i]),
                .carry(stage3_carry[i])
            );
        end
    endgenerate

    // Fourth stage: reduce 4 to 2
    generate
        for (i = 0; i < 2; i = i + 1) begin : stage4
            wallace_full_adder_64 fa4 (
                .a(stage3_sum[i*2]),
                .b(stage3_sum[i*2+1]),
                .cin(stage3_carry[i*2]),
                .sum(stage4_sum[i]),
                .carry(stage4_carry[i])
            );
        end
    endgenerate

    // Fifth stage: reduce 2 to 1 (final sum and carry)
    wallace_full_adder_64 fa5 (
        .a(stage4_sum[0]),
        .b(stage4_sum[1]),
        .cin(stage4_carry[0]),
        .sum(stage5_sum),
        .carry(stage5_carry)
    );

    // Final product: sum + carry shifted left by 1
    assign product = stage5_sum + (stage5_carry << 1);

endmodule

module wallace_full_adder_64 (
    input  [63:0] a,
    input  [63:0] b,
    input  [63:0] cin,
    output [63:0] sum,
    output [63:0] carry
);
    assign sum   = a ^ b ^ cin;
    assign carry = (a & b) | (b & cin) | (a & cin);
endmodule