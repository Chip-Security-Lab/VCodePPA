//SystemVerilog
module rng_async_mix_7(
    input      [7:0] in_cnt,
    output     [7:0] out_rand
);
    wire [3:0] lower_nibble;
    wire [3:0] upper_nibble;
    wire [1:0] lower_2bits;
    wire [1:0] mid_2bits;
    wire [1:0] upper_2bits;
    wire [3:0] brent_kung_sum;

    assign lower_nibble = in_cnt[3:0];
    assign upper_nibble = in_cnt[7:4];
    assign lower_2bits  = in_cnt[1:0];
    assign mid_2bits    = in_cnt[3:2];
    assign upper_2bits  = in_cnt[5:4];

    brent_kung_adder_4bit u_bk_adder_4bit (
        .a    ({2'b00, lower_2bits}),
        .b    ({2'b00, mid_2bits}),
        .sum  (brent_kung_sum)
    );

    assign out_rand = {lower_nibble ^ upper_nibble, brent_kung_sum[1:0] ^ upper_2bits};
endmodule

module brent_kung_adder_4bit (
    input  [3:0] a,
    input  [3:0] b,
    output [3:0] sum
);
    wire [3:0] p, g;
    wire [3:0] c;

    // Generate and propagate
    assign p = a ^ b;
    assign g = a & b;

    // Brent-Kung parallel prefix
    // Stage 1
    wire g1_0, p1_0;
    wire g2_1, p2_1;
    wire g3_2, p3_2;
    wire g3_1, p3_1;

    assign g1_0 = g[1] | (p[1] & g[0]);
    assign p1_0 = p[1] & p[0];

    assign g2_1 = g[2] | (p[2] & g[1]);
    assign p2_1 = p[2] & p[1];

    assign g3_2 = g[3] | (p[3] & g[2]);
    assign p3_2 = p[3] & p[2];

    // Stage 2
    assign g3_1 = g3_2 | (p3_2 & g1_0);
    assign p3_1 = p3_2 & p1_0;

    // Carry chain
    assign c[0] = 1'b0;
    assign c[1] = g[0];
    assign c[2] = g1_0;
    assign c[3] = g3_1;

    assign sum = p ^ c;
endmodule