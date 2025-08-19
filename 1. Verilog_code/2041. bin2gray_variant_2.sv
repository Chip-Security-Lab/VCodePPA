//SystemVerilog
module bin2gray #(parameter WIDTH = 8) (
    input wire [WIDTH-1:0] bin_in,
    output wire [WIDTH-1:0] gray_out
);
    wire [WIDTH-1:0] bin_shifted;
    wire [WIDTH-1:0] bin_inverted;
    wire [WIDTH-1:0] twos_complement_sum;

    // Shifted input for subtraction
    assign bin_shifted = bin_in >> 1;

    // Two's complement subtraction using Han-Carlson adder: bin_in - bin_shifted
    assign bin_inverted = ~bin_shifted;

    han_carlson_adder_8bit u_han_carlson_adder (
        .a     (bin_in),
        .b     (bin_inverted),
        .cin   (1'b1),
        .sum   (twos_complement_sum),
        .cout  ()
    );

    // Output is XOR of bin_in and bin_in >> 1 (functionally unchanged)
    assign gray_out = twos_complement_sum;
endmodule

// Han-Carlson 8-bit adder module
module han_carlson_adder_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       cin,
    output wire [7:0] sum,
    output wire       cout
);
    wire [7:0] p, g;
    wire [7:0] c;

    // Pre-processing
    assign p = a ^ b;
    assign g = a & b;

    // Han-Carlson prefix computation

    // Stage 0: Initial generate and propagate
    wire [7:0] gnpg_0, pp_0;
    assign gnpg_0 = g;
    assign pp_0   = p;

    // Stage 1
    wire [7:0] gnpg_1, pp_1;
    assign gnpg_1[0] = gnpg_0[0];
    assign pp_1[0]   = pp_0[0];
    genvar i1;
    generate
        for (i1 = 1; i1 < 8; i1 = i1 + 1) begin : HC_STAGE1
            assign gnpg_1[i1] = gnpg_0[i1] | (pp_0[i1] & gnpg_0[i1-1]);
            assign pp_1[i1]   = pp_0[i1] & pp_0[i1-1];
        end
    endgenerate

    // Stage 2
    wire [7:0] gnpg_2, pp_2;
    assign gnpg_2[0] = gnpg_1[0];
    assign gnpg_2[1] = gnpg_1[1];
    assign pp_2[0]   = pp_1[0];
    assign pp_2[1]   = pp_1[1];
    genvar i2;
    generate
        for (i2 = 2; i2 < 8; i2 = i2 + 1) begin : HC_STAGE2
            assign gnpg_2[i2] = gnpg_1[i2] | (pp_1[i2] & gnpg_1[i2-2]);
            assign pp_2[i2]   = pp_1[i2] & pp_1[i2-2];
        end
    endgenerate

    // Stage 3
    wire [7:0] gnpg_3, pp_3;
    assign gnpg_3[0] = gnpg_2[0];
    assign gnpg_3[1] = gnpg_2[1];
    assign gnpg_3[2] = gnpg_2[2];
    assign gnpg_3[3] = gnpg_2[3];
    assign pp_3[0]   = pp_2[0];
    assign pp_3[1]   = pp_2[1];
    assign pp_3[2]   = pp_2[2];
    assign pp_3[3]   = pp_2[3];
    genvar i3;
    generate
        for (i3 = 4; i3 < 8; i3 = i3 + 1) begin : HC_STAGE3
            assign gnpg_3[i3] = gnpg_2[i3] | (pp_2[i3] & gnpg_2[i3-4]);
            assign pp_3[i3]   = pp_2[i3] & pp_2[i3-4];
        end
    endgenerate

    // Post-processing: Compute carries
    assign c[0] = cin;
    assign c[1] = gnpg_0[0] | (pp_0[0] & cin);
    assign c[2] = gnpg_1[1] | (pp_1[1] & cin);
    assign c[3] = gnpg_2[2] | (pp_2[2] & cin);
    assign c[4] = gnpg_3[3] | (pp_3[3] & cin);
    assign c[5] = gnpg_3[4] | (pp_3[4] & c[1]);
    assign c[6] = gnpg_3[5] | (pp_3[5] & c[2]);
    assign c[7] = gnpg_3[6] | (pp_3[6] & c[3]);
    assign cout = gnpg_3[7] | (pp_3[7] & c[4]);

    // Sum computation
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = p[4] ^ c[4];
    assign sum[5] = p[5] ^ c[5];
    assign sum[6] = p[6] ^ c[6];
    assign sum[7] = p[7] ^ c[7];
endmodule