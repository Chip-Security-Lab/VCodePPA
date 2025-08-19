//SystemVerilog
// Top-level module: Hierarchical dither and truncate logic
module dither_trunc_top #(parameter DATA_WIDTH = 16)(
    input  wire [DATA_WIDTH+3:0] data_in,
    output wire [DATA_WIDTH-1:0] data_out
);

    // Internal signals
    wire [2:0]   lfsr_value;
    wire         dither_flag;
    wire [DATA_WIDTH-1:0] trunc_sum;

    // LFSR Generator Instance
    dither_lfsr_3bit u_dither_lfsr_3bit (
        .event_vector  (data_in),
        .lfsr_data     (lfsr_value)
    );

    // Dither Comparator Instance
    dither_comparator u_dither_comparator (
        .lsb_in        (data_in[3:0]),
        .lfsr_in       (lfsr_value),
        .dither_enable (dither_flag)
    );

    // Truncation and Dither Addition Instance (Brent-Kung adder)
    trunc_dither_adder #(.IN_WIDTH(DATA_WIDTH)) u_trunc_dither_adder (
        .trunc_in      (data_in[DATA_WIDTH+3:4]),
        .dither_in     (dither_flag),
        .sum_out       (trunc_sum)
    );

    assign data_out = trunc_sum;

endmodule

//------------------------------------------------------------------------------
// 3-bit LFSR Dither Generator
// Generates a 3-bit pseudo-random sequence for dithering
//------------------------------------------------------------------------------
module dither_lfsr_3bit (
    input  wire [18:0] event_vector, // Event-driven trigger (input vector)
    output reg  [2:0]  lfsr_data
);
    reg [2:0] lfsr_state = 3'b101;

    always @(event_vector) begin
        lfsr_state <= {lfsr_state[1:0], lfsr_state[2] ^ lfsr_state[1]};
    end

    always @(*) begin
        lfsr_data = lfsr_state;
    end

endmodule

//------------------------------------------------------------------------------
// Dither Comparator
// Compares input lower bits with LFSR output to generate dither enable signal
//------------------------------------------------------------------------------
module dither_comparator (
    input  wire [3:0] lsb_in,
    input  wire [2:0] lfsr_in,
    output wire       dither_enable
);
    assign dither_enable = (lsb_in > {1'b0, lfsr_in}) ? 1'b1 : 1'b0;
endmodule

//------------------------------------------------------------------------------
// Truncation and Dither Adder (Brent-Kung 19-bit adder for IN_WIDTH up to 19)
//------------------------------------------------------------------------------
module trunc_dither_adder #(
    parameter IN_WIDTH = 16
)(
    input  wire [IN_WIDTH-1:0] trunc_in,
    input  wire                dither_in,
    output wire [IN_WIDTH-1:0] sum_out
);
    // Zero-extend to 19 bits for Brent-Kung adder
    wire [18:0] operand_a;
    wire [18:0] operand_b;
    wire [18:0] brent_kung_sum;

    assign operand_a = {{(19-IN_WIDTH){1'b0}}, trunc_in};
    assign operand_b = {{18{1'b0}}, dither_in}; // dither_in as LSB

    brent_kung_adder_19 u_brent_kung_adder_19 (
        .a (operand_a),
        .b (operand_b),
        .sum (brent_kung_sum)
    );

    assign sum_out = brent_kung_sum[IN_WIDTH-1:0];
endmodule

//------------------------------------------------------------------------------
// Brent-Kung 19-bit Adder
//------------------------------------------------------------------------------
module brent_kung_adder_19(
    input  wire [18:0] a,
    input  wire [18:0] b,
    output wire [18:0] sum
);
    wire [18:0] p, g;
    wire [18:0] c;

    // Generate and propagate
    assign p = a ^ b;
    assign g = a & b;

    // Level 0
    wire [18:0] g0, p0;
    assign g0 = g;
    assign p0 = p;

    // Level 1
    wire [18:0] g1, p1;
    assign g1[0] = g0[0];
    assign p1[0] = p0[0];
    genvar i1;
    generate
        for (i1 = 1; i1 < 19; i1 = i1 + 1) begin : BK_L1
            assign g1[i1] = g0[i1] | (p0[i1] & g0[i1-1]);
            assign p1[i1] = p0[i1] & p0[i1-1];
        end
    endgenerate

    // Level 2
    wire [18:0] g2, p2;
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    genvar i2;
    generate
        for (i2 = 2; i2 < 19; i2 = i2 + 1) begin : BK_L2
            assign g2[i2] = g1[i2] | (p1[i2] & g1[i2-2]);
            assign p2[i2] = p1[i2] & p1[i2-2];
        end
    endgenerate

    // Level 3
    wire [18:0] g3, p3;
    assign g3[0] = g2[0];
    assign p3[0] = p2[0];
    assign g3[1] = g2[1];
    assign p3[1] = p2[1];
    assign g3[2] = g2[2];
    assign p3[2] = p2[2];
    assign g3[3] = g2[3];
    assign p3[3] = p2[3];
    genvar i3;
    generate
        for (i3 = 4; i3 < 19; i3 = i3 + 1) begin : BK_L3
            assign g3[i3] = g2[i3] | (p2[i3] & g2[i3-4]);
            assign p3[i3] = p2[i3] & p2[i3-4];
        end
    endgenerate

    // Level 4
    wire [18:0] g4, p4;
    assign g4[0] = g3[0];
    assign p4[0] = p3[0];
    assign g4[1] = g3[1];
    assign p4[1] = p3[1];
    assign g4[2] = g3[2];
    assign p4[2] = p3[2];
    assign g4[3] = g3[3];
    assign p4[3] = p3[3];
    assign g4[4] = g3[4];
    assign p4[4] = p3[4];
    assign g4[5] = g3[5];
    assign p4[5] = p3[5];
    assign g4[6] = g3[6];
    assign p4[6] = p3[6];
    assign g4[7] = g3[7];
    assign p4[7] = p3[7];
    genvar i4;
    generate
        for (i4 = 8; i4 < 19; i4 = i4 + 1) begin : BK_L4
            assign g4[i4] = g3[i4] | (p3[i4] & g3[i4-8]);
            assign p4[i4] = p3[i4] & p3[i4-8];
        end
    endgenerate

    // Carry computation
    assign c[0] = 1'b0;
    assign c[1] = g0[0];
    assign c[2] = g1[1];
    assign c[3] = g2[2];
    assign c[4] = g3[3];
    assign c[5] = g4[4];
    assign c[6] = g4[5];
    assign c[7] = g4[6];
    assign c[8] = g4[7];
    assign c[9] = g4[8];
    assign c[10] = g4[9];
    assign c[11] = g4[10];
    assign c[12] = g4[11];
    assign c[13] = g4[12];
    assign c[14] = g4[13];
    assign c[15] = g4[14];
    assign c[16] = g4[15];
    assign c[17] = g4[16];
    assign c[18] = g4[17];

    // Sum bits
    genvar is;
    generate
        for (is = 0; is < 19; is = is + 1) begin : BK_SUM
            assign sum[is] = p[is] ^ c[is];
        end
    endgenerate
endmodule