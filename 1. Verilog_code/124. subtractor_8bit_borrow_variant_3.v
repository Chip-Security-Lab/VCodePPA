module subtractor_8bit_borrow (
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff,
    output borrow
);

    wire [7:0] b_comp;
    wire [7:0] sum;
    wire carry_out;

    // 补码生成模块
    complement_generator comp_gen (
        .in(b),
        .out(b_comp)
    );

    // 先行进位加法器模块
    carry_lookahead_adder_8bit adder (
        .a(a),
        .b(b_comp),
        .cin(1'b1),
        .sum(sum),
        .cout(carry_out)
    );

    // 结果处理模块
    result_processor result_proc (
        .sum(sum),
        .carry(carry_out),
        .diff(diff),
        .borrow(borrow)
    );

endmodule

module complement_generator (
    input [7:0] in,
    output [7:0] out
);
    assign out = ~in;
endmodule

module carry_lookahead_adder_8bit (
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [7:0] g, p;
    wire [7:0] carry;
    
    // 生成和传播信号
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_block
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate
    
    // 先行进位计算
    assign carry[0] = cin;
    assign carry[1] = g[0] | (p[0] & cin);
    assign carry[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    assign carry[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
    assign carry[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin);
    assign carry[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & cin);
    assign carry[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & cin);
    assign cout = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & cin);
    
    // 和计算
    genvar j;
    generate
        for (j = 0; j < 8; j = j + 1) begin : sum_block
            assign sum[j] = p[j] ^ carry[j];
        end
    endgenerate
endmodule

module result_processor (
    input [7:0] sum,
    input carry,
    output [7:0] diff,
    output borrow
);
    assign diff = sum;
    assign borrow = ~carry;
endmodule