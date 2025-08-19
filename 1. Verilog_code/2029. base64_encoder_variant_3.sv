//SystemVerilog
module base64_encoder (
    input  wire [23:0] data,
    output reg  [31:0] encoded
);

    wire [31:0] kogge_stone_input_a;
    wire [31:0] kogge_stone_input_b;
    wire [63:0] kogge_stone_product;

    // Example: Use Kogge-Stone multiply on two 32-bit segments of data
    assign kogge_stone_input_a = {8'b0, data[23:8]};  // Pad to 32 bits for demonstration
    assign kogge_stone_input_b = {8'b0, data[15:0]};  // Pad to 32 bits for demonstration

    kogge_stone_multiplier_32x32 u_ks_mult (
        .multiplicand(kogge_stone_input_a),
        .multiplier(kogge_stone_input_b),
        .product(kogge_stone_product)
    );

    always @* begin
        encoded[31:26] = data[23:18];
        encoded[25:20] = data[17:12];
        encoded[19:14] = data[11:6];
        encoded[13:8]  = data[5:0];
        // Example: Insert lower 8 bits of Kogge-Stone result
        encoded[7:0]   = kogge_stone_product[7:0];
    end
endmodule

module kogge_stone_multiplier_32x32 (
    input  wire [31:0] multiplicand,
    input  wire [31:0] multiplier,
    output wire [63:0] product
);
    wire [63:0] partial_products [31:0];
    wire [63:0] sum_stage [31:0];

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_partial_products
            assign partial_products[i] = (multiplier[i]) ? (multiplicand << i) : 64'b0;
        end
    endgenerate

    // Use a tree of 64-bit Kogge-Stone adders to sum the partial products
    wire [63:0] adder_sum_0;
    wire [63:0] adder_sum_1;
    wire [63:0] adder_sum_2;
    wire [63:0] adder_sum_3;
    wire [63:0] adder_sum_4;
    wire [63:0] adder_sum_5;
    wire [63:0] adder_sum_6;
    wire [63:0] adder_sum_7;
    wire [63:0] adder_sum_8;
    wire [63:0] adder_sum_9;
    wire [63:0] adder_sum_10;
    wire [63:0] adder_sum_11;
    wire [63:0] adder_sum_12;
    wire [63:0] adder_sum_13;
    wire [63:0] adder_sum_14;
    wire [63:0] adder_sum_15;

    // First level
    kogge_stone_adder_64 u_ksa0  (.a(partial_products[0]),  .b(partial_products[1]),  .sum(adder_sum_0));
    kogge_stone_adder_64 u_ksa1  (.a(partial_products[2]),  .b(partial_products[3]),  .sum(adder_sum_1));
    kogge_stone_adder_64 u_ksa2  (.a(partial_products[4]),  .b(partial_products[5]),  .sum(adder_sum_2));
    kogge_stone_adder_64 u_ksa3  (.a(partial_products[6]),  .b(partial_products[7]),  .sum(adder_sum_3));
    kogge_stone_adder_64 u_ksa4  (.a(partial_products[8]),  .b(partial_products[9]),  .sum(adder_sum_4));
    kogge_stone_adder_64 u_ksa5  (.a(partial_products[10]), .b(partial_products[11]), .sum(adder_sum_5));
    kogge_stone_adder_64 u_ksa6  (.a(partial_products[12]), .b(partial_products[13]), .sum(adder_sum_6));
    kogge_stone_adder_64 u_ksa7  (.a(partial_products[14]), .b(partial_products[15]), .sum(adder_sum_7));
    kogge_stone_adder_64 u_ksa8  (.a(partial_products[16]), .b(partial_products[17]), .sum(adder_sum_8));
    kogge_stone_adder_64 u_ksa9  (.a(partial_products[18]), .b(partial_products[19]), .sum(adder_sum_9));
    kogge_stone_adder_64 u_ksa10 (.a(partial_products[20]), .b(partial_products[21]), .sum(adder_sum_10));
    kogge_stone_adder_64 u_ksa11 (.a(partial_products[22]), .b(partial_products[23]), .sum(adder_sum_11));
    kogge_stone_adder_64 u_ksa12 (.a(partial_products[24]), .b(partial_products[25]), .sum(adder_sum_12));
    kogge_stone_adder_64 u_ksa13 (.a(partial_products[26]), .b(partial_products[27]), .sum(adder_sum_13));
    kogge_stone_adder_64 u_ksa14 (.a(partial_products[28]), .b(partial_products[29]), .sum(adder_sum_14));
    kogge_stone_adder_64 u_ksa15 (.a(partial_products[30]), .b(partial_products[31]), .sum(adder_sum_15));

    // Second level
    wire [63:0] adder_sum_16;
    wire [63:0] adder_sum_17;
    wire [63:0] adder_sum_18;
    wire [63:0] adder_sum_19;
    wire [63:0] adder_sum_20;
    wire [63:0] adder_sum_21;
    wire [63:0] adder_sum_22;
    wire [63:0] adder_sum_23;

    kogge_stone_adder_64 u_ksa16 (.a(adder_sum_0),  .b(adder_sum_1),  .sum(adder_sum_16));
    kogge_stone_adder_64 u_ksa17 (.a(adder_sum_2),  .b(adder_sum_3),  .sum(adder_sum_17));
    kogge_stone_adder_64 u_ksa18 (.a(adder_sum_4),  .b(adder_sum_5),  .sum(adder_sum_18));
    kogge_stone_adder_64 u_ksa19 (.a(adder_sum_6),  .b(adder_sum_7),  .sum(adder_sum_19));
    kogge_stone_adder_64 u_ksa20 (.a(adder_sum_8),  .b(adder_sum_9),  .sum(adder_sum_20));
    kogge_stone_adder_64 u_ksa21 (.a(adder_sum_10), .b(adder_sum_11), .sum(adder_sum_21));
    kogge_stone_adder_64 u_ksa22 (.a(adder_sum_12), .b(adder_sum_13), .sum(adder_sum_22));
    kogge_stone_adder_64 u_ksa23 (.a(adder_sum_14), .b(adder_sum_15), .sum(adder_sum_23));

    // Third level
    wire [63:0] adder_sum_24;
    wire [63:0] adder_sum_25;
    wire [63:0] adder_sum_26;
    wire [63:0] adder_sum_27;

    kogge_stone_adder_64 u_ksa24 (.a(adder_sum_16), .b(adder_sum_17), .sum(adder_sum_24));
    kogge_stone_adder_64 u_ksa25 (.a(adder_sum_18), .b(adder_sum_19), .sum(adder_sum_25));
    kogge_stone_adder_64 u_ksa26 (.a(adder_sum_20), .b(adder_sum_21), .sum(adder_sum_26));
    kogge_stone_adder_64 u_ksa27 (.a(adder_sum_22), .b(adder_sum_23), .sum(adder_sum_27));

    // Fourth level
    wire [63:0] adder_sum_28;
    wire [63:0] adder_sum_29;

    kogge_stone_adder_64 u_ksa28 (.a(adder_sum_24), .b(adder_sum_25), .sum(adder_sum_28));
    kogge_stone_adder_64 u_ksa29 (.a(adder_sum_26), .b(adder_sum_27), .sum(adder_sum_29));

    // Fifth level
    wire [63:0] adder_sum_30;

    kogge_stone_adder_64 u_ksa30 (.a(adder_sum_28), .b(adder_sum_29), .sum(adder_sum_30));

    // Final sum
    assign product = adder_sum_30;

endmodule

module kogge_stone_adder_64 (
    input  wire [63:0] a,
    input  wire [63:0] b,
    output wire [63:0] sum
);
    wire [63:0] generate_stage [0:6];
    wire [63:0] propagate_stage [0:6];
    wire [63:0] carry;

    assign generate_stage[0] = a & b;
    assign propagate_stage[0] = a ^ b;

    genvar stage, bit_idx;
    generate
        // Kogge-Stone prefix computation for 64 bits, 6 stages
        for (stage = 1; stage <= 6; stage = stage + 1) begin : gen_ks_stage
            for (bit_idx = 0; bit_idx < 64; bit_idx = bit_idx + 1) begin : gen_ks_bit
                if (bit_idx >= (1 << (stage - 1))) begin
                    assign generate_stage[stage][bit_idx] =
                        generate_stage[stage-1][bit_idx] |
                        (propagate_stage[stage-1][bit_idx] & generate_stage[stage-1][bit_idx - (1 << (stage - 1))]);
                    assign propagate_stage[stage][bit_idx] =
                        propagate_stage[stage-1][bit_idx] &
                        propagate_stage[stage-1][bit_idx - (1 << (stage - 1))];
                end else begin
                    assign generate_stage[stage][bit_idx] = generate_stage[stage-1][bit_idx];
                    assign propagate_stage[stage][bit_idx] = propagate_stage[stage-1][bit_idx];
                end
            end
        end
    endgenerate

    assign carry[0] = 1'b0;
    generate
        for (bit_idx = 1; bit_idx < 64; bit_idx = bit_idx + 1) begin : gen_carry
            assign carry[bit_idx] = generate_stage[6][bit_idx - 1];
        end
    endgenerate

    assign sum = propagate_stage[0] ^ carry;

endmodule