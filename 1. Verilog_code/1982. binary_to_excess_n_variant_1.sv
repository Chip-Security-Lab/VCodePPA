//SystemVerilog
module binary_to_excess_n #(parameter WIDTH=8, N=127)(
    input wire [WIDTH-1:0] binary_in,
    output wire [WIDTH-1:0] excess_n_out
);

    wire [WIDTH-1:0] n_const;
    assign n_const = N[WIDTH-1:0];

    wire [WIDTH-1:0] sum;
    wire carry_out;

    parallel_prefix_adder_8bit u_parallel_prefix_adder_8bit (
        .a(binary_in),
        .b(n_const),
        .sum(sum),
        .carry_out(carry_out)
    );

    assign excess_n_out = sum;

endmodule

module parallel_prefix_adder_8bit(
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum,
    output wire       carry_out
);
    // Generate and Propagate
    wire [7:0] g, p;
    assign g = a & b;
    assign p = a ^ b;

    // Carry signals
    wire [7:0] c;

    // Stage 0
    wire [7:0] g0, p0;
    assign g0 = g;
    assign p0 = p;

    // Stage 1
    wire [7:0] g1, p1;
    assign g1[0] = g0[0];
    assign p1[0] = p0[0];
    assign g1[1] = g0[1] | (p0[1] & g0[0]);
    assign p1[1] = p0[1] & p0[0];
    assign g1[2] = g0[2] | (p0[2] & g0[1]);
    assign p1[2] = p0[2] & p0[1];
    assign g1[3] = g0[3] | (p0[3] & g0[2]);
    assign p1[3] = p0[3] & p0[2];
    assign g1[4] = g0[4] | (p0[4] & g0[3]);
    assign p1[4] = p0[4] & p0[3];
    assign g1[5] = g0[5] | (p0[5] & g0[4]);
    assign p1[5] = p0[5] & p0[4];
    assign g1[6] = g0[6] | (p0[6] & g0[5]);
    assign p1[6] = p0[6] & p0[5];
    assign g1[7] = g0[7] | (p0[7] & g0[6]);
    assign p1[7] = p0[7] & p0[6];

    // Stage 2
    wire [7:0] g2, p2;
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];
    assign g2[4] = g1[4] | (p1[4] & g1[2]);
    assign p2[4] = p1[4] & p1[2];
    assign g2[5] = g1[5] | (p1[5] & g1[3]);
    assign p2[5] = p1[5] & p1[3];
    assign g2[6] = g1[6] | (p1[6] & g1[4]);
    assign p2[6] = p1[6] & p1[4];
    assign g2[7] = g1[7] | (p1[7] & g1[5]);
    assign p2[7] = p1[7] & p1[5];

    // Stage 3
    wire [7:0] g3, p3;
    assign g3[0] = g2[0];
    assign p3[0] = p2[0];
    assign g3[1] = g2[1];
    assign p3[1] = p2[1];
    assign g3[2] = g2[2];
    assign p3[2] = p2[2];
    assign g3[3] = g2[3];
    assign p3[3] = p2[3];
    assign g3[4] = g2[4] | (p2[4] & g2[0]);
    assign p3[4] = p2[4] & p2[0];
    assign g3[5] = g2[5] | (p2[5] & g2[1]);
    assign p3[5] = p2[5] & p2[1];
    assign g3[6] = g2[6] | (p2[6] & g2[2]);
    assign p3[6] = p2[6] & p2[2];
    assign g3[7] = g2[7] | (p2[7] & g2[3]);
    assign p3[7] = p2[7] & p2[3];

    // Stage 4
    wire [7:0] g4;
    assign g4[0] = g3[0];
    assign g4[1] = g3[1];
    assign g4[2] = g3[2];
    assign g4[3] = g3[3];
    assign g4[4] = g3[4];
    assign g4[5] = g3[5];
    assign g4[6] = g3[6] | (p3[6] & g3[2]);
    assign g4[7] = g3[7] | (p3[7] & g3[3]);

    // Carry chain
    assign c[0] = 1'b0;
    assign c[1] = g0[0];
    assign c[2] = g1[1];
    assign c[3] = g2[2];
    assign c[4] = g3[3];
    assign c[5] = g4[4];
    assign c[6] = g4[5];
    assign c[7] = g4[6];
    assign carry_out = g4[7];

    // Sum
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = p[4] ^ c[4];
    assign sum[5] = p[5] ^ c[5];
    assign sum[6] = p[6] ^ c[6];
    assign sum[7] = p[7] ^ c[7];

endmodule