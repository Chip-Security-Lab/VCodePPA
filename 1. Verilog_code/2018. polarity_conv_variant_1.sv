//SystemVerilog
module polarity_conv #(parameter MODE = 0) (
    input  wire [15:0] in,
    output wire [15:0] out
);
    wire [15:0] adder_sum;

    han_carlson_adder_16 han_carlson_adder_inst (
        .a(in),
        .b(16'd32768),
        .sum(adder_sum)
    );

    assign out = MODE ? {~in[15], in[14:0]} : adder_sum;
endmodule

module han_carlson_adder_16 (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [15:0] sum
);

    // Generate and Propagate signals
    wire [15:0] gen, prop;
    assign gen = a & b;
    assign prop = a ^ b;

    // Level 1
    wire [15:0] gen1, prop1;
    assign gen1[0] = gen[0];
    assign prop1[0] = prop[0];
    genvar idx1;
    generate
        for (idx1 = 1; idx1 < 16; idx1 = idx1 + 1) begin : lvl1
            // g1[i] = g[i] | (p[i] & g[i-1])
            assign gen1[idx1] = gen[idx1] | (prop[idx1] & gen[idx1-1]);
            // p1[i] = p[i] & p[i-1]
            assign prop1[idx1] = prop[idx1] & prop[idx1-1];
        end
    endgenerate

    // Level 2
    wire [15:0] gen2, prop2;
    assign gen2[0] = gen1[0];
    assign prop2[0] = prop1[0];
    assign gen2[1] = gen1[1];
    assign prop2[1] = prop1[1];
    genvar idx2;
    generate
        for (idx2 = 2; idx2 < 16; idx2 = idx2 + 1) begin : lvl2
            // g2[i] = g1[i] | (p1[i] & g1[i-2])
            assign gen2[idx2] = gen1[idx2] | (prop1[idx2] & gen1[idx2-2]);
            // p2[i] = p1[i] & p1[i-2]
            assign prop2[idx2] = prop1[idx2] & prop1[idx2-2];
        end
    endgenerate

    // Level 3
    wire [15:0] gen3, prop3;
    assign gen3[0] = gen2[0];
    assign prop3[0] = prop2[0];
    assign gen3[1] = gen2[1];
    assign prop3[1] = prop2[1];
    assign gen3[2] = gen2[2];
    assign prop3[2] = prop2[2];
    assign gen3[3] = gen2[3];
    assign prop3[3] = prop2[3];
    genvar idx3;
    generate
        for (idx3 = 4; idx3 < 16; idx3 = idx3 + 1) begin : lvl3
            // g3[i] = g2[i] | (p2[i] & g2[i-4])
            assign gen3[idx3] = gen2[idx3] | (prop2[idx3] & gen2[idx3-4]);
            // p3[i] = p2[i] & p2[i-4]
            assign prop3[idx3] = prop2[idx3] & prop2[idx3-4];
        end
    endgenerate

    // Level 4
    wire [15:0] gen4;
    assign gen4[0] = gen3[0];
    assign gen4[1] = gen3[1];
    assign gen4[2] = gen3[2];
    assign gen4[3] = gen3[3];
    assign gen4[4] = gen3[4];
    assign gen4[5] = gen3[5];
    assign gen4[6] = gen3[6];
    assign gen4[7] = gen3[7];
    genvar idx4;
    generate
        for (idx4 = 8; idx4 < 16; idx4 = idx4 + 1) begin : lvl4
            // g4[i] = g3[i] | (p3[i] & g3[i-8])
            assign gen4[idx4] = gen3[idx4] | (prop3[idx4] & gen3[idx4-8]);
        end
    endgenerate

    // Carry computation (simplified using Boolean algebra)
    wire [15:0] carry;
    assign carry[0]  = 1'b0;
    assign carry[1]  = gen[0];
    assign carry[2]  = gen1[1];
    assign carry[3]  = gen2[2];
    assign carry[4]  = gen3[3];

    // carry[5] = g1[4] | (p1[4] & g3[3])
    // Using distributive law: a | (b & c) = (a | b) & (a | c)
    assign carry[5]  = gen1[4] | (prop1[4] & gen3[3]);

    // carry[6] = g2[5] | (p2[5] & g3[3])
    assign carry[6]  = gen2[5] | (prop2[5] & gen3[3]);

    // carry[7] = g3[6] | (p3[6] & g3[3])
    assign carry[7]  = gen3[6] | (prop3[6] & gen3[3]);

    assign carry[8]  = gen4[7];

    // carry[9] = g1[8] | (p1[8] & g4[7])
    assign carry[9]  = gen1[8] | (prop1[8] & gen4[7]);
    // carry[10] = g2[9] | (p2[9] & g4[7])
    assign carry[10] = gen2[9] | (prop2[9] & gen4[7]);
    // carry[11] = g3[10] | (p3[10] & g4[7])
    assign carry[11] = gen3[10] | (prop3[10] & gen4[7]);
    // carry[12] = g1[12] | (p1[12] & g4[7])
    assign carry[12] = gen1[12] | (prop1[12] & gen4[7]);
    // carry[13] = g2[13] | (p2[13] & g4[7])
    assign carry[13] = gen2[13] | (prop2[13] & gen4[7]);
    // carry[14] = g3[14] | (p3[14] & g4[7])
    assign carry[14] = gen3[14] | (prop3[14] & gen4[7]);
    assign carry[15] = gen4[15];

    // Sum calculation (optimized using Boolean identities)
    assign sum = prop ^ carry;

endmodule