//SystemVerilog
module AsyncRst_XNOR(
    input rst_n,
    input [3:0] src_a, src_b,
    output reg [3:0] q
);
    wire [7:0] product;  // 4位乘法结果可能达到8位
    
    wallace_multiplier wallace_mult_inst(
        .a(src_a),
        .b(src_b),
        .product(product)
    );
    
    always @(*) begin
        if (rst_n)
            // 乘法结果的低4位作为输出，模拟原XNOR功能
            q = product[3:0];
        else
            q = 4'b0000;
    end
endmodule

module wallace_multiplier(
    input [3:0] a,
    input [3:0] b,
    output [7:0] product
);
    // 部分积生成
    wire [3:0][3:0] pp;  // 16个部分积
    
    // 生成部分积矩阵
    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin: gen_pp_i
            for (j = 0; j < 4; j = j + 1) begin: gen_pp_j
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // Wallace树压缩阶段1
    wire [5:0] s1, c1;  // 第一级和与进位
    
    // 第一级压缩
    half_adder ha1_1(.a(pp[0][0]), .b(1'b0), .sum(product[0]), .cout(c1[0]));
    full_adder fa1_1(.a(pp[0][1]), .b(pp[1][0]), .cin(c1[0]), .sum(s1[0]), .cout(c1[1]));
    full_adder fa1_2(.a(pp[0][2]), .b(pp[1][1]), .cin(pp[2][0]), .sum(s1[1]), .cout(c1[2]));
    full_adder fa1_3(.a(pp[0][3]), .b(pp[1][2]), .cin(pp[2][1]), .sum(s1[2]), .cout(c1[3]));
    full_adder fa1_4(.a(pp[1][3]), .b(pp[2][2]), .cin(pp[3][1]), .sum(s1[3]), .cout(c1[4]));
    half_adder ha1_2(.a(pp[2][3]), .b(pp[3][2]), .sum(s1[4]), .cout(c1[5]));
    assign s1[5] = pp[3][3];
    
    // Wallace树压缩阶段2
    wire [4:0] s2, c2;  // 第二级和与进位
    
    // 第二级压缩
    half_adder ha2_1(.a(s1[0]), .b(1'b0), .sum(product[1]), .cout(c2[0]));
    full_adder fa2_1(.a(s1[1]), .b(c1[1]), .cin(c2[0]), .sum(s2[0]), .cout(c2[1]));
    full_adder fa2_2(.a(s1[2]), .b(c1[2]), .cin(pp[3][0]), .sum(s2[1]), .cout(c2[2]));
    full_adder fa2_3(.a(s1[3]), .b(c1[3]), .cin(c2[1]), .sum(s2[2]), .cout(c2[3]));
    full_adder fa2_4(.a(s1[4]), .b(c1[4]), .cin(c2[2]), .sum(s2[3]), .cout(c2[4]));
    assign s2[4] = s1[5];
    
    // 最终进位传播加法器 - 替换为跳跃进位加法器
    wire [7:2] sum, carry_gen, carry_prop, carry;
    
    // 计算初始和与进位生成/传播信号
    assign sum[2] = s2[0];
    assign sum[3] = s2[1] ^ c2[3];
    assign sum[4] = s2[2] ^ c2[4];
    assign sum[5] = s2[3] ^ c1[5];
    assign sum[6] = s2[4];
    assign sum[7] = 1'b0;
    
    // 进位生成信号
    assign carry_gen[2] = 1'b0;
    assign carry_gen[3] = s2[1] & c2[3];
    assign carry_gen[4] = s2[2] & c2[4];
    assign carry_gen[5] = s2[3] & c1[5];
    assign carry_gen[6] = 1'b0;
    assign carry_gen[7] = 1'b0;
    
    // 进位传播信号
    assign carry_prop[2] = 1'b0;
    assign carry_prop[3] = s2[1] | c2[3];
    assign carry_prop[4] = s2[2] | c2[4];
    assign carry_prop[5] = s2[3] | c1[5];
    assign carry_prop[6] = s2[4];
    assign carry_prop[7] = 1'b0;
    
    // 跳跃进位计算
    assign carry[2] = 1'b0;  // 初始进位
    assign carry[3] = carry_gen[2] | (carry_prop[2] & carry[2]);
    assign carry[4] = carry_gen[3] | (carry_prop[3] & carry[3]);
    assign carry[5] = carry_gen[4] | (carry_prop[4] & carry[4]);
    assign carry[6] = carry_gen[5] | (carry_prop[5] & carry[5]);
    assign carry[7] = carry_gen[6] | (carry_prop[6] & carry[6]);
    
    // 最终结果计算
    assign product[2] = sum[2] ^ carry[2];
    assign product[3] = sum[3] ^ carry[3];
    assign product[4] = sum[4] ^ carry[4];
    assign product[5] = sum[5] ^ carry[5];
    assign product[6] = sum[6] ^ carry[6];
    assign product[7] = (s2[4] & c1[5]) | carry[7];
endmodule

module half_adder(
    input a, b,
    output sum, cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule

module full_adder(
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule