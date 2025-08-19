module subtractor_8bit (
    input wire [7:0] operand_a,
    input wire [7:0] operand_b,
    output wire [7:0] result
);

    wire [7:0] inverted_b;
    wire [7:0] sum;
    wire carry_out;

    twos_complement_8bit complement_converter (
        .input_data(operand_b),
        .output_data(inverted_b)
    );

    adder_8bit adder (
        .operand_a(operand_a),
        .operand_b(inverted_b),
        .carry_in(1'b1),
        .sum(sum),
        .carry_out(carry_out)
    );

    assign result = sum;

endmodule

module twos_complement_8bit (
    input wire [7:0] input_data,
    output wire [7:0] output_data
);

    assign output_data = ~input_data;

endmodule

module adder_8bit (
    input wire [7:0] operand_a,
    input wire [7:0] operand_b,
    input wire carry_in,
    output wire [7:0] sum,
    output wire carry_out
);

    // 生成和传播信号
    wire [7:0] g;  // 生成信号
    wire [7:0] p;  // 传播信号
    wire [7:0] c;  // 进位信号

    // 计算生成和传播信号
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_prop
            assign g[i] = operand_a[i] & operand_b[i];
            assign p[i] = operand_a[i] ^ operand_b[i];
        end
    endgenerate

    // 计算进位
    assign c[0] = carry_in;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | 
                 (p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | 
                 (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | 
                 (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | 
                 (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | 
                 (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | 
                 (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | 
                 (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);

    // 计算和
    genvar j;
    generate
        for (j = 0; j < 8; j = j + 1) begin : sum_gen
            assign sum[j] = p[j] ^ c[j];
        end
    endgenerate

    assign carry_out = c[7];

endmodule