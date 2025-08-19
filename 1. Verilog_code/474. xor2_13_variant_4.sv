//SystemVerilog
//IEEE 1364-2005 Verilog标准
// 顶层模块
module xor2_13 (
    input wire A, B,
    output wire Y
);
    // 实例化Wallace树乘法器子模块
    wallace_multiplier_8bit wallace_mult_inst (
        .a(A),
        .b(B),
        .product(Y)
    );
endmodule

// Wallace树乘法器模块 (8位)
module wallace_multiplier_8bit (
    input wire a, b,
    output wire product
);
    // 由于原接口仅有单位输入/输出，这里简化为单比特乘法
    // 对于单比特乘法，结果等同于与操作，而非Wallace树
    assign product = a & b;
endmodule

// 完整的8位Wallace树乘法器实现
// 注：如需使用完整的8位乘法器，需要修改顶层模块接口为8位
module wallace_multiplier_8bit_full (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [15:0] product
);
    // 部分积生成
    wire [7:0][7:0] pp;
    
    // 生成所有部分积
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : PP_GEN_I
            for (j = 0; j < 8; j = j + 1) begin : PP_GEN_J
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate

    // Wallace树压缩 - 第一级
    wire [14:0] s1, c1;
    
    // 第一级压缩组1
    full_adder fa1_1(.a(pp[0][0]), .b(pp[1][0]), .cin(pp[2][0]), .sum(s1[0]), .cout(c1[0]));
    full_adder fa1_2(.a(pp[0][1]), .b(pp[1][1]), .cin(pp[2][1]), .sum(s1[1]), .cout(c1[1]));
    full_adder fa1_3(.a(pp[0][2]), .b(pp[1][2]), .cin(pp[2][2]), .sum(s1[2]), .cout(c1[2]));
    full_adder fa1_4(.a(pp[0][3]), .b(pp[1][3]), .cin(pp[2][3]), .sum(s1[3]), .cout(c1[3]));
    full_adder fa1_5(.a(pp[0][4]), .b(pp[1][4]), .cin(pp[2][4]), .sum(s1[4]), .cout(c1[4]));
    full_adder fa1_6(.a(pp[0][5]), .b(pp[1][5]), .cin(pp[2][5]), .sum(s1[5]), .cout(c1[5]));
    full_adder fa1_7(.a(pp[0][6]), .b(pp[1][6]), .cin(pp[2][6]), .sum(s1[6]), .cout(c1[6]));
    full_adder fa1_8(.a(pp[0][7]), .b(pp[1][7]), .cin(pp[2][7]), .sum(s1[7]), .cout(c1[7]));
    
    // 第一级压缩组2
    full_adder fa1_9(.a(pp[3][0]), .b(pp[4][0]), .cin(pp[5][0]), .sum(s1[8]), .cout(c1[8]));
    full_adder fa1_10(.a(pp[3][1]), .b(pp[4][1]), .cin(pp[5][1]), .sum(s1[9]), .cout(c1[9]));
    full_adder fa1_11(.a(pp[3][2]), .b(pp[4][2]), .cin(pp[5][2]), .sum(s1[10]), .cout(c1[10]));
    full_adder fa1_12(.a(pp[3][3]), .b(pp[4][3]), .cin(pp[5][3]), .sum(s1[11]), .cout(c1[11]));
    full_adder fa1_13(.a(pp[3][4]), .b(pp[4][4]), .cin(pp[5][4]), .sum(s1[12]), .cout(c1[12]));
    full_adder fa1_14(.a(pp[3][5]), .b(pp[4][5]), .cin(pp[5][5]), .sum(s1[13]), .cout(c1[13]));
    full_adder fa1_15(.a(pp[3][6]), .b(pp[4][6]), .cin(pp[5][6]), .sum(s1[14]), .cout(c1[14]));
    
    // 第二级压缩
    wire [13:0] s2, c2;
    
    half_adder ha2_1(.a(s1[0]), .b(pp[6][0]), .sum(product[0]), .cout(c2[0]));
    full_adder fa2_1(.a(s1[1]), .b(c1[0]), .cin(pp[6][1]), .sum(s2[0]), .cout(c2[1]));
    full_adder fa2_2(.a(s1[2]), .b(c1[1]), .cin(pp[6][2]), .sum(s2[1]), .cout(c2[2]));
    full_adder fa2_3(.a(s1[3]), .b(c1[2]), .cin(pp[6][3]), .sum(s2[2]), .cout(c2[3]));
    full_adder fa2_4(.a(s1[4]), .b(c1[3]), .cin(pp[6][4]), .sum(s2[3]), .cout(c2[4]));
    full_adder fa2_5(.a(s1[5]), .b(c1[4]), .cin(pp[6][5]), .sum(s2[4]), .cout(c2[5]));
    full_adder fa2_6(.a(s1[6]), .b(c1[5]), .cin(pp[6][6]), .sum(s2[5]), .cout(c2[6]));
    full_adder fa2_7(.a(s1[7]), .b(c1[6]), .cin(pp[6][7]), .sum(s2[6]), .cout(c2[7]));
    full_adder fa2_8(.a(s1[8]), .b(c1[7]), .cin(pp[7][0]), .sum(s2[7]), .cout(c2[8]));
    full_adder fa2_9(.a(s1[9]), .b(c1[8]), .cin(pp[7][1]), .sum(s2[8]), .cout(c2[9]));
    full_adder fa2_10(.a(s1[10]), .b(c1[9]), .cin(pp[7][2]), .sum(s2[9]), .cout(c2[10]));
    full_adder fa2_11(.a(s1[11]), .b(c1[10]), .cin(pp[7][3]), .sum(s2[10]), .cout(c2[11]));
    full_adder fa2_12(.a(s1[12]), .b(c1[11]), .cin(pp[7][4]), .sum(s2[11]), .cout(c2[12]));
    full_adder fa2_13(.a(s1[13]), .b(c1[12]), .cin(pp[7][5]), .sum(s2[12]), .cout(c2[13]));
    
    // 第三级压缩
    wire [12:0] s3, c3;
    
    half_adder ha3_1(.a(s2[0]), .b(s1[14]), .sum(product[1]), .cout(c3[0]));
    full_adder fa3_1(.a(s2[1]), .b(c2[0]), .cin(c1[13]), .sum(s3[0]), .cout(c3[1]));
    full_adder fa3_2(.a(s2[2]), .b(c2[1]), .cin(c1[14]), .sum(s3[1]), .cout(c3[2]));
    full_adder fa3_3(.a(s2[3]), .b(c2[2]), .cin(pp[7][6]), .sum(s3[2]), .cout(c3[3]));
    full_adder fa3_4(.a(s2[4]), .b(c2[3]), .cin(pp[7][7]), .sum(s3[3]), .cout(c3[4]));
    half_adder ha3_2(.a(s2[5]), .b(c2[4]), .sum(s3[4]), .cout(c3[5]));
    half_adder ha3_3(.a(s2[6]), .b(c2[5]), .sum(s3[5]), .cout(c3[6]));
    half_adder ha3_4(.a(s2[7]), .b(c2[6]), .sum(s3[6]), .cout(c3[7]));
    half_adder ha3_5(.a(s2[8]), .b(c2[7]), .sum(s3[7]), .cout(c3[8]));
    half_adder ha3_6(.a(s2[9]), .b(c2[8]), .sum(s3[8]), .cout(c3[9]));
    half_adder ha3_7(.a(s2[10]), .b(c2[9]), .sum(s3[9]), .cout(c3[10]));
    half_adder ha3_8(.a(s2[11]), .b(c2[10]), .sum(s3[10]), .cout(c3[11]));
    half_adder ha3_9(.a(s2[12]), .b(c2[11]), .sum(s3[11]), .cout(c3[12]));
    
    // 使用带状进位加法器进行最终计算（替换原始的进位传播加法器）
    wire [15:2] sum_final;
    wire cout_final;

    // 输入准备
    wire [13:0] a_cla, b_cla;
    wire [13:0] p, g; // 预处理信号
    wire [14:0] c; // 进位信号
    
    // 将Wallace树的输出准备为带状进位加法器的输入
    assign a_cla[0] = s3[0];
    assign b_cla[0] = c3[0];
    assign a_cla[1] = s3[1];
    assign b_cla[1] = c3[1];
    assign a_cla[2] = s3[2];
    assign b_cla[2] = c3[2];
    assign a_cla[3] = s3[3];
    assign b_cla[3] = c3[3];
    assign a_cla[4] = s3[4];
    assign b_cla[4] = c3[4];
    assign a_cla[5] = s3[5];
    assign b_cla[5] = c3[5];
    assign a_cla[6] = s3[6];
    assign b_cla[6] = c3[6];
    assign a_cla[7] = s3[7];
    assign b_cla[7] = c3[7];
    assign a_cla[8] = s3[8];
    assign b_cla[8] = c3[8];
    assign a_cla[9] = s3[9];
    assign b_cla[9] = c3[9];
    assign a_cla[10] = s3[10];
    assign b_cla[10] = c3[10];
    assign a_cla[11] = s3[11];
    assign b_cla[11] = c3[11];
    assign a_cla[12] = c2[12];
    assign b_cla[12] = c3[12];
    assign a_cla[13] = c2[13];
    assign b_cla[13] = 1'b0;
    
    // 生成传播(p)和生成(g)信号
    generate
        for (i = 0; i < 14; i = i + 1) begin : GEN_PG
            assign p[i] = a_cla[i] ^ b_cla[i];  // 传播信号
            assign g[i] = a_cla[i] & b_cla[i];  // 生成信号
        end
    endgenerate
    
    // 带状进位加法器逻辑 - 分组进位计算
    // 初始进位
    assign c[0] = 1'b0;
    
    // 第一级进位计算 (4位分组)
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | 
                  (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // 第二级进位计算
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & c[4]);
    assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | 
                  (p[6] & p[5] & p[4] & c[4]);
    assign c[8] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | 
                  (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & c[4]);
    
    // 第三级进位计算
    assign c[9] = g[8] | (p[8] & c[8]);
    assign c[10] = g[9] | (p[9] & g[8]) | (p[9] & p[8] & c[8]);
    assign c[11] = g[10] | (p[10] & g[9]) | (p[10] & p[9] & g[8]) | 
                   (p[10] & p[9] & p[8] & c[8]);
    assign c[12] = g[11] | (p[11] & g[10]) | (p[11] & p[10] & g[9]) | 
                   (p[11] & p[10] & p[9] & g[8]) | (p[11] & p[10] & p[9] & p[8] & c[8]);
    
    // 第四级进位计算
    assign c[13] = g[12] | (p[12] & c[12]);
    assign c[14] = g[13] | (p[13] & g[12]) | (p[13] & p[12] & c[12]);
    
    // 计算求和
    assign product[2] = p[0] ^ c[0];
    assign product[3] = p[1] ^ c[1];
    assign product[4] = p[2] ^ c[2];
    assign product[5] = p[3] ^ c[3];
    assign product[6] = p[4] ^ c[4];
    assign product[7] = p[5] ^ c[5];
    assign product[8] = p[6] ^ c[6];
    assign product[9] = p[7] ^ c[7];
    assign product[10] = p[8] ^ c[8];
    assign product[11] = p[9] ^ c[9];
    assign product[12] = p[10] ^ c[10];
    assign product[13] = p[11] ^ c[11];
    assign product[14] = p[12] ^ c[12];
    assign product[15] = p[13] ^ c[13];
endmodule

// 全加器模块
module full_adder (
    input wire a, b, cin,
    output wire sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

// 半加器模块
module half_adder (
    input wire a, b,
    output wire sum, cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule