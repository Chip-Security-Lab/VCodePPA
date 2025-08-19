//SystemVerilog
module neg_edge_sync_reset_reg(
    input clk, rst,
    input [15:0] d_in,
    input load,
    output reg [15:0] q_out
);
    reg [1:0] ctrl;
    reg [15:0] mult_result;
    reg [15:0] operand_a, operand_b;
    
    // 控制信号逻辑
    always @(*) begin
        ctrl = {rst, load};
    end
    
    // Wallace树乘法器实现
    wallace_tree_multiplier u_mult (
        .a(operand_a),
        .b(operand_b),
        .result(mult_result)
    );
    
    // 寄存器输入数据选择与复位逻辑
    always @(negedge clk) begin
        if (rst) begin
            q_out <= 16'b0;
            operand_a <= 16'b0;
            operand_b <= 16'b0;
        end else if (load) begin
            q_out <= d_in;
            // 将输入数据分割为乘法器操作数
            operand_a <= d_in;
            operand_b <= q_out;
        end else begin
            q_out <= q_out;
        end
    end
endmodule

// Wallace树乘法器模块
module wallace_tree_multiplier(
    input [15:0] a,
    input [15:0] b,
    output [15:0] result
);
    // 部分积生成
    wire [15:0] pp[15:0];
    wire [31:0] full_result;
    
    // 生成部分积
    genvar i, j;
    generate
        for (i = 0; i < 16; i = i + 1) begin: gen_pp_row
            for (j = 0; j < 16; j = j + 1) begin: gen_pp_col
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // Wallace树压缩阶段
    // 第一级压缩 - 将16个部分积压缩为11个部分和
    wire [31:0] s1_1, s1_2, s1_3, s1_4, s1_5;
    wire [31:0] c1_1, c1_2, c1_3, c1_4, c1_5;
    
    // 将部分积扩展为32位
    wire [31:0] pp_ext[15:0];
    generate
        for (i = 0; i < 16; i = i + 1) begin: extend_pp
            assign pp_ext[i] = {{(16){1'b0}}, pp[i]} << i;
        end
    endgenerate
    
    // 第一级压缩
    csa_32bit csa1_1(.a(pp_ext[0]), .b(pp_ext[1]), .c(pp_ext[2]), .sum(s1_1), .carry(c1_1));
    csa_32bit csa1_2(.a(pp_ext[3]), .b(pp_ext[4]), .c(pp_ext[5]), .sum(s1_2), .carry(c1_2));
    csa_32bit csa1_3(.a(pp_ext[6]), .b(pp_ext[7]), .c(pp_ext[8]), .sum(s1_3), .carry(c1_3));
    csa_32bit csa1_4(.a(pp_ext[9]), .b(pp_ext[10]), .c(pp_ext[11]), .sum(s1_4), .carry(c1_4));
    csa_32bit csa1_5(.a(pp_ext[12]), .b(pp_ext[13]), .c(pp_ext[14]), .sum(s1_5), .carry(c1_5));
    
    // 第二级压缩 - 将11个部分和压缩为7个部分和
    wire [31:0] s2_1, s2_2, s2_3;
    wire [31:0] c2_1, c2_2, c2_3;
    
    csa_32bit csa2_1(.a(s1_1), .b(c1_1 << 1), .c(s1_2), .sum(s2_1), .carry(c2_1));
    csa_32bit csa2_2(.a(c1_2 << 1), .b(s1_3), .c(c1_3 << 1), .sum(s2_2), .carry(c2_2));
    csa_32bit csa2_3(.a(s1_4), .b(c1_4 << 1), .c(s1_5), .sum(s2_3), .carry(c2_3));
    
    // 第三级压缩 - 将7个部分和压缩为5个部分和
    wire [31:0] s3_1, s3_2;
    wire [31:0] c3_1, c3_2;
    
    csa_32bit csa3_1(.a(s2_1), .b(c2_1 << 1), .c(s2_2), .sum(s3_1), .carry(c3_1));
    csa_32bit csa3_2(.a(c2_2 << 1), .b(s2_3), .c(c2_3 << 1), .sum(s3_2), .carry(c3_2));
    
    // 第四级压缩 - 将5个部分和压缩为3个部分和
    wire [31:0] s4_1;
    wire [31:0] c4_1;
    
    csa_32bit csa4_1(.a(s3_1), .b(c3_1 << 1), .c(s3_2), .sum(s4_1), .carry(c4_1));
    
    // 第五级压缩 - 将3个部分和压缩为2个部分和
    wire [31:0] s5_1;
    wire [31:0] c5_1;
    
    csa_32bit csa5_1(.a(s4_1), .b(c4_1 << 1), .c(c3_2 << 1), .sum(s5_1), .carry(c5_1));
    
    // 最终加法，使用行波进位加法器
    assign full_result = s5_1 + (c5_1 << 1) + pp_ext[15];
    
    // 截取需要的16位结果
    assign result = full_result[15:0];
endmodule

// 三输入进位保存加法器(CSA)
module csa_32bit(
    input [31:0] a, b, c,
    output [31:0] sum, carry
);
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin: gen_csa
            full_adder fa(
                .a(a[i]),
                .b(b[i]),
                .cin(c[i]),
                .sum(sum[i]),
                .cout(carry[i])
            );
        end
    endgenerate
endmodule

// 全加器
module full_adder(
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule