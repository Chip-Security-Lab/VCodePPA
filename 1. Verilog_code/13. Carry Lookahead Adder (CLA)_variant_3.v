module kogge_stone_adder(
    input [4:0] a, b,
    input cin,
    output [4:0] sum,
    output cout
);

    wire [4:0] g, p;
    wire [4:0] c;
    wire [4:0] g_stage1, p_stage1;
    wire [4:0] g_stage2, p_stage2;
    wire [4:0] g_stage3, p_stage3;

    // Stage 0: Generate initial g and p signals
    gen_prop_gen gpg(
        .a(a),
        .b(b),
        .g(g),
        .p(p)
    );

    // Stage 1: First parallel prefix stage
    parallel_prefix pp1(
        .g_in(g),
        .p_in(p),
        .g_out(g_stage1),
        .p_out(p_stage1)
    );

    // Stage 2: Second parallel prefix stage
    parallel_prefix pp2(
        .g_in(g_stage1),
        .p_in(p_stage1),
        .g_out(g_stage2),
        .p_out(p_stage2)
    );

    // Stage 3: Final parallel prefix stage
    parallel_prefix pp3(
        .g_in(g_stage2),
        .p_in(p_stage2),
        .g_out(g_stage3),
        .p_out(p_stage3)
    );

    // Generate carries
    assign c[0] = cin;
    assign c[1] = g_stage3[0] | (p_stage3[0] & cin);
    assign c[2] = g_stage3[1] | (p_stage3[1] & cin);
    assign c[3] = g_stage3[2] | (p_stage3[2] & cin);
    assign c[4] = g_stage3[3] | (p_stage3[3] & cin);
    assign cout = c[4];

    // Generate sum
    sum_gen sg(
        .a(a),
        .b(b),
        .c(c),
        .sum(sum)
    );

endmodule

module gen_prop_gen(
    input [4:0] a, b,
    output [4:0] g, p
);
    assign g = a & b;
    assign p = a ^ b;
endmodule

module parallel_prefix(
    input [4:0] g_in, p_in,
    output [4:0] g_out, p_out
);
    genvar i;
    generate
        for(i = 0; i < 5; i = i + 1) begin: pp
            if(i == 0) begin
                assign g_out[i] = g_in[i];
                assign p_out[i] = p_in[i];
            end
            else begin
                assign g_out[i] = g_in[i] | (p_in[i] & g_in[i-1]);
                assign p_out[i] = p_in[i] & p_in[i-1];
            end
        end
    endgenerate
endmodule

module sum_gen(
    input [4:0] a, b, c,
    output [4:0] sum
);
    assign sum = a ^ b ^ c;
endmodule