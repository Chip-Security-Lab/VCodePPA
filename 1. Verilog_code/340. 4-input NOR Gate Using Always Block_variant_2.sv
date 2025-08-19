//SystemVerilog
module wallace_tree_multiplier_8bit (
    input  wire [7:0] multiplicand,
    input  wire [7:0] multiplier,
    output wire [15:0] product
);
    wire [7:0] pp [7:0];

    // Partial products generation
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_partial_products
            assign pp[i] = multiplicand & {8{multiplier[i]}};
        end
    endgenerate

    // Wallace tree reduction

    // First stage: sum of partial products (pairwise)
    wire [7:0] sum_s1_0, carry_s1_0;
    wire [7:0] sum_s1_1, carry_s1_1;
    wire [7:0] sum_s1_2, carry_s1_2;

    // Stage 1
    assign {carry_s1_0[7], sum_s1_0[7:0]} = {1'b0, pp[0]} + {1'b0, pp[1]};
    assign {carry_s1_1[7], sum_s1_1[7:0]} = {1'b0, pp[2]} + {1'b0, pp[3]};
    assign {carry_s1_2[7], sum_s1_2[7:0]} = {1'b0, pp[4]} + {1'b0, pp[5]};

    // Stage 2
    wire [8:0] sum_s2_0, carry_s2_0;
    wire [8:0] sum_s2_1, carry_s2_1;

    assign {carry_s2_0[8], sum_s2_0[8:0]} = {carry_s1_0[7], sum_s1_0} + {carry_s1_1[7], sum_s1_1};
    assign {carry_s2_1[8], sum_s2_1[8:0]} = {carry_s1_2[7], sum_s1_2} + {1'b0, pp[6]};

    // Stage 3
    wire [9:0] sum_s3_0, carry_s3_0;

    assign {carry_s3_0[9], sum_s3_0[9:0]} = {carry_s2_0[8], sum_s2_0} + {carry_s2_1[8], sum_s2_1};

    // Add last partial product pp[7]
    wire [10:0] sum_final, carry_final;
    assign {carry_final[10], sum_final[10:0]} = {carry_s3_0[9], sum_s3_0} + {2'b0, pp[7]};

    // Final addition (carry + sum)
    assign product = {carry_final[10:0], 5'b0} + {5'b0, sum_final[10:0]};

endmodule