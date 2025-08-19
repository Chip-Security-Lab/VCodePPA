//SystemVerilog
module Comparator_BaseAsync #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] data_a,
    input  [WIDTH-1:0] data_b,
    output             o_equal
);

    wire [WIDTH-1:0] diff;
    wire             zero_flag;

    ParallelPrefixSubtractor #(.WIDTH(WIDTH)) subtractor (
        .a(data_a),
        .b(data_b),
        .diff(diff),
        .zero_flag(zero_flag)
    );

    assign o_equal = zero_flag;

endmodule

module ParallelPrefixSubtractor #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [WIDTH-1:0] diff,
    output             zero_flag
);

    // Stage 1: Generate and Propagate
    wire [WIDTH-1:0] g_stage1, p_stage1;
    wire [WIDTH:0]   carry_stage1;
    assign carry_stage1[0] = 1'b1;
    assign g_stage1 = ~a & b;
    assign p_stage1 = a ^ b;

    // Stage 2: First Level Prefix
    wire [WIDTH-1:0] g_stage2, p_stage2;
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : prefix_level1
            if (i == 0) begin
                assign g_stage2[i] = g_stage1[i] | (p_stage1[i] & carry_stage1[0]);
                assign p_stage2[i] = p_stage1[i];
            end else begin
                assign g_stage2[i] = g_stage1[i] | (p_stage1[i] & g_stage1[i-1]);
                assign p_stage2[i] = p_stage1[i] & p_stage1[i-1];
            end
        end
    endgenerate

    // Stage 3: Second Level Prefix
    wire [WIDTH-1:0] g_stage3, p_stage3;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : prefix_level2
            if (i < 2) begin
                assign g_stage3[i] = g_stage2[i];
                assign p_stage3[i] = p_stage2[i];
            end else begin
                assign g_stage3[i] = g_stage2[i] | (p_stage2[i] & g_stage2[i-2]);
                assign p_stage3[i] = p_stage2[i] & p_stage2[i-2];
            end
        end
    endgenerate

    // Stage 4: Third Level Prefix
    wire [WIDTH-1:0] g_stage4, p_stage4;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : prefix_level3
            if (i < 4) begin
                assign g_stage4[i] = g_stage3[i];
                assign p_stage4[i] = p_stage3[i];
            end else begin
                assign g_stage4[i] = g_stage3[i] | (p_stage3[i] & g_stage3[i-4]);
                assign p_stage4[i] = p_stage3[i] & p_stage3[i-4];
            end
        end
    endgenerate

    // Stage 5: Final Carry Generation
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : final_carry
            assign carry_stage1[i+1] = g_stage4[i];
        end
    endgenerate

    // Stage 6: Difference Calculation
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : diff_calc
            assign diff[i] = p_stage1[i] ^ ~carry_stage1[i];
        end
    endgenerate

    // Stage 7: Zero Detection
    assign zero_flag = ~|diff;

endmodule