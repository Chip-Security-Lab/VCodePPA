module carry_skip_adder(
    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output cout
);

    // Stage 1: Generate propagate and generate signals
    wire [3:0] p, g;
    assign p = a ^ b;
    assign g = a & b;

    // Stage 2: Block 0 carry computation
    wire block0_c1, block0_c2;
    wire block0_skip;
    
    block_0_stage blk0(
        .g0(g[0]), .p0(p[0]),
        .g1(g[1]), .p1(p[1]),
        .cin(cin),
        .c1(block0_c1),
        .c2(block0_c2),
        .skip(block0_skip)
    );

    // Stage 3: Block 1 carry computation
    wire block1_c3, block1_c4;
    
    block_1_stage blk1(
        .g2(g[2]), .p2(p[2]),
        .g3(g[3]), .p3(p[3]),
        .c2(block0_c2),
        .c0(cin),
        .skip(block0_skip),
        .c3(block1_c3),
        .c4(block1_c4)
    );

    // Stage 4: Final sum computation
    assign sum = p ^ {block1_c3, block0_c2, block0_c1, cin};
    assign cout = block1_c4;

endmodule

module block_0_stage(
    input g0, p0,
    input g1, p1,
    input cin,
    output c1,
    output c2,
    output skip
);
    // Stage 1: First carry computation
    wire stage1_c1;
    assign stage1_c1 = g0 | (p0 & cin);
    
    // Stage 2: Second carry computation
    assign c1 = stage1_c1;
    assign c2 = g1 | (p1 & stage1_c1);
    assign skip = p0 & p1;
endmodule

module block_1_stage(
    input g2, p2,
    input g3, p3,
    input c2, c0,
    input skip,
    output c3,
    output c4
);
    // Stage 1: First carry computation with skip logic
    wire stage1_c3;
    assign stage1_c3 = skip ? c0 : (g2 | (p2 & c2));
    
    // Stage 2: Second carry computation
    assign c3 = stage1_c3;
    assign c4 = g3 | (p3 & stage1_c3);
endmodule