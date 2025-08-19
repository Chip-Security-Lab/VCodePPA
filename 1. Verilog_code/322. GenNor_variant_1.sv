//SystemVerilog
// Top-level NOR array generator module with Kogge-Stone 8-bit adder
module GenNor #(parameter N=8)(
    input  wire [N-1:0] in_a,
    input  wire [N-1:0] in_b,
    output wire [N-1:0] out_y,
    input  wire [N-1:0] add_a,
    input  wire [N-1:0] add_b,
    output wire [N-1:0] sum_out
);

    // Generate N instances of the single-bit NOR cell
    genvar idx;
    generate
        for (idx = 0; idx < N; idx = idx + 1) begin : GEN_NOR_CELL
            NorCell nor_cell_inst (
                .a_bit (in_a[idx]),
                .b_bit (in_b[idx]),
                .y_bit (out_y[idx])
            );
        end
    endgenerate

    // Kogge-Stone 8-bit adder instantiation
    KoggeStoneAdder8 kogge_stone_adder_inst (
        .a        (add_a),
        .b        (add_b),
        .sum      (sum_out)
    );

endmodule

// -----------------------------------------------------------------------------
// NorCell: Single-bit NOR gate cell
// Performs logical NOR operation on two input bits
// -----------------------------------------------------------------------------
module NorCell(
    input  wire a_bit,
    input  wire b_bit,
    output wire y_bit
);
    assign y_bit = ~(a_bit | b_bit);
endmodule

// -----------------------------------------------------------------------------
// Kogge-Stone 8-bit Adder
// Implements an 8-bit Kogge-Stone parallel prefix adder
// -----------------------------------------------------------------------------
module KoggeStoneAdder8(
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum
);

    wire [7:0] generate_signal;
    wire [7:0] propagate_signal;

    // Stage 0: Initial propagate and generate
    assign generate_signal   = a & b;
    assign propagate_signal  = a ^ b;

    // Stage 1
    wire [7:0] g_stage1;
    wire [7:0] p_stage1;
    assign g_stage1[0] = generate_signal[0];
    assign p_stage1[0] = propagate_signal[0];
    genvar i1;
    generate
        for (i1 = 1; i1 < 8; i1 = i1 + 1) begin : STAGE1
            assign g_stage1[i1] = generate_signal[i1] | (propagate_signal[i1] & generate_signal[i1-1]);
            assign p_stage1[i1] = propagate_signal[i1] & propagate_signal[i1-1];
        end
    endgenerate

    // Stage 2
    wire [7:0] g_stage2;
    wire [7:0] p_stage2;
    assign g_stage2[0] = g_stage1[0];
    assign p_stage2[0] = p_stage1[0];
    assign g_stage2[1] = g_stage1[1];
    assign p_stage2[1] = p_stage1[1];
    genvar i2;
    generate
        for (i2 = 2; i2 < 8; i2 = i2 + 1) begin : STAGE2
            assign g_stage2[i2] = g_stage1[i2] | (p_stage1[i2] & g_stage1[i2-2]);
            assign p_stage2[i2] = p_stage1[i2] & p_stage1[i2-2];
        end
    endgenerate

    // Stage 3
    wire [7:0] g_stage3;
    wire [7:0] p_stage3;
    assign g_stage3[0] = g_stage2[0];
    assign p_stage3[0] = p_stage2[0];
    assign g_stage3[1] = g_stage2[1];
    assign p_stage3[1] = p_stage2[1];
    assign g_stage3[2] = g_stage2[2];
    assign p_stage3[2] = p_stage2[2];
    assign g_stage3[3] = g_stage2[3];
    assign p_stage3[3] = p_stage2[3];
    genvar i3;
    generate
        for (i3 = 4; i3 < 8; i3 = i3 + 1) begin : STAGE3
            assign g_stage3[i3] = g_stage2[i3] | (p_stage2[i3] & g_stage2[i3-4]);
            assign p_stage3[i3] = p_stage2[i3] & p_stage2[i3-4];
        end
    endgenerate

    // Carry calculation
    wire [7:0] carry;
    assign carry[0] = 1'b0;
    assign carry[1] = g_stage3[0];
    assign carry[2] = g_stage3[1];
    assign carry[3] = g_stage3[2];
    assign carry[4] = g_stage3[3];
    assign carry[5] = g_stage3[4];
    assign carry[6] = g_stage3[5];
    assign carry[7] = g_stage3[6];

    // Sum calculation
    assign sum[0] = propagate_signal[0] ^ carry[0];
    assign sum[1] = propagate_signal[1] ^ carry[1];
    assign sum[2] = propagate_signal[2] ^ carry[2];
    assign sum[3] = propagate_signal[3] ^ carry[3];
    assign sum[4] = propagate_signal[4] ^ carry[4];
    assign sum[5] = propagate_signal[5] ^ carry[5];
    assign sum[6] = propagate_signal[6] ^ carry[6];
    assign sum[7] = propagate_signal[7] ^ carry[7];

endmodule