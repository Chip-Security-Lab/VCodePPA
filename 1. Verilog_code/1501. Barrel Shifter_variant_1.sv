//SystemVerilog
// SystemVerilog
// IEEE 1364-2005
module barrel_shifter (
    input wire [7:0] data_in,
    input wire [2:0] shift_amount,
    input wire direction, // 0: right, 1: left
    output reg [7:0] data_out
);
    // 声明内部信号
    wire [7:0] multiplicand;
    wire [7:0] multiplier;
    wire [15:0] product;
    
    // 移位器到乘法器的映射逻辑
    assign multiplicand = data_in;
    
    // 分离移位量计算
    wire [7:0] left_shift_value;
    wire [7:0] right_shift_value;
    
    assign left_shift_value = 8'h01 << shift_amount;
    assign right_shift_value = 8'h80 >> shift_amount;
    
    // 根据方向选择乘数
    assign multiplier = direction ? left_shift_value : right_shift_value;
    
    // 使用Wallace树乘法器计算乘积
    wallace_tree_multiplier wallace_mult (
        .a(multiplicand),
        .b(multiplier),
        .product(product)
    );
    
    // 输出结果处理
    always @(*) begin
        if (direction)
            data_out = product[7:0];
        else
            data_out = product[15:8];
    end
endmodule

// Wallace树乘法器模块
module wallace_tree_multiplier (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [15:0] product
);
    // 部分积生成
    wire [7:0] pp [7:0]; // 8个部分积，每个8位
    
    // 生成部分积 - 通过generate语句
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin: pp_gen
            for (j = 0; j < 8; j = j + 1) begin: pp_bit
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // Wallace树压缩 - 第一级信号
    wire [14:0] s1_1, c1_1;
    
    // 第一级压缩 - 第一组 (pp[0], pp[1], pp[2])
    wallace_stage1_group1 stage1_g1 (
        .pp0(pp[0]),
        .pp1(pp[1]),
        .pp2(pp[2]),
        .sum(s1_1[7:0]),
        .cout(c1_1[7:0])
    );
    
    // 第一级压缩 - 第二组 (pp[3], pp[4], pp[5])
    wallace_stage1_group2 stage1_g2 (
        .pp3(pp[3]),
        .pp4(pp[4]),
        .pp5(pp[5]),
        .sum(s1_1[14:8]),
        .cout(c1_1[14:8])
    );
    
    // Wallace树压缩 - 第二级信号
    wire [14:0] s2_1, c2_1;
    
    // 第二级压缩
    wallace_stage2 stage2 (
        .s1(s1_1),
        .c1(c1_1),
        .pp6(pp[6]),
        .pp7(pp[7]),
        .s2(s2_1),
        .c2(c2_1)
    );
    
    // 最终加法阶段
    final_adder_stage final_stage (
        .s2(s2_1),
        .c2(c2_1),
        .product(product)
    );
endmodule

// 第一级压缩 - 第一组模块
module wallace_stage1_group1 (
    input wire [7:0] pp0,
    input wire [7:0] pp1,
    input wire [7:0] pp2,
    output wire [7:0] sum,
    output wire [7:0] cout
);
    full_adder fa0 (.a(pp0[0]), .b(pp1[0]), .cin(pp2[0]), .sum(sum[0]), .cout(cout[0]));
    full_adder fa1 (.a(pp0[1]), .b(pp1[1]), .cin(pp2[1]), .sum(sum[1]), .cout(cout[1]));
    full_adder fa2 (.a(pp0[2]), .b(pp1[2]), .cin(pp2[2]), .sum(sum[2]), .cout(cout[2]));
    full_adder fa3 (.a(pp0[3]), .b(pp1[3]), .cin(pp2[3]), .sum(sum[3]), .cout(cout[3]));
    full_adder fa4 (.a(pp0[4]), .b(pp1[4]), .cin(pp2[4]), .sum(sum[4]), .cout(cout[4]));
    full_adder fa5 (.a(pp0[5]), .b(pp1[5]), .cin(pp2[5]), .sum(sum[5]), .cout(cout[5]));
    full_adder fa6 (.a(pp0[6]), .b(pp1[6]), .cin(pp2[6]), .sum(sum[6]), .cout(cout[6]));
    full_adder fa7 (.a(pp0[7]), .b(pp1[7]), .cin(pp2[7]), .sum(sum[7]), .cout(cout[7]));
endmodule

// 第一级压缩 - 第二组模块
module wallace_stage1_group2 (
    input wire [7:0] pp3,
    input wire [7:0] pp4,
    input wire [7:0] pp5,
    output wire [6:0] sum,
    output wire [6:0] cout
);
    full_adder fa0 (.a(pp3[0]), .b(pp4[0]), .cin(pp5[0]), .sum(sum[0]), .cout(cout[0]));
    full_adder fa1 (.a(pp3[1]), .b(pp4[1]), .cin(pp5[1]), .sum(sum[1]), .cout(cout[1]));
    full_adder fa2 (.a(pp3[2]), .b(pp4[2]), .cin(pp5[2]), .sum(sum[2]), .cout(cout[2]));
    full_adder fa3 (.a(pp3[3]), .b(pp4[3]), .cin(pp5[3]), .sum(sum[3]), .cout(cout[3]));
    full_adder fa4 (.a(pp3[4]), .b(pp4[4]), .cin(pp5[4]), .sum(sum[4]), .cout(cout[4]));
    full_adder fa5 (.a(pp3[5]), .b(pp4[5]), .cin(pp5[5]), .sum(sum[5]), .cout(cout[5]));
    full_adder fa6 (.a(pp3[6]), .b(pp4[6]), .cin(pp5[6]), .sum(sum[6]), .cout(cout[6]));
endmodule

// 第二级压缩模块
module wallace_stage2 (
    input wire [14:0] s1,
    input wire [14:0] c1,
    input wire [7:0] pp6,
    input wire [7:0] pp7,
    output wire [14:0] s2,
    output wire [14:0] c2
);
    // 第一组处理
    half_adder ha0 (.a(s1[0]), .b(pp6[0]), .sum(s2[0]), .cout(c2[0]));
    full_adder fa1 (.a(s1[1]), .b(c1[0]), .cin(pp6[1]), .sum(s2[1]), .cout(c2[1]));
    full_adder fa2 (.a(s1[2]), .b(c1[1]), .cin(pp6[2]), .sum(s2[2]), .cout(c2[2]));
    full_adder fa3 (.a(s1[3]), .b(c1[2]), .cin(pp6[3]), .sum(s2[3]), .cout(c2[3]));
    full_adder fa4 (.a(s1[4]), .b(c1[3]), .cin(pp6[4]), .sum(s2[4]), .cout(c2[4]));
    full_adder fa5 (.a(s1[5]), .b(c1[4]), .cin(pp6[5]), .sum(s2[5]), .cout(c2[5]));
    full_adder fa6 (.a(s1[6]), .b(c1[5]), .cin(pp6[6]), .sum(s2[6]), .cout(c2[6]));
    full_adder fa7 (.a(s1[7]), .b(c1[6]), .cin(pp6[7]), .sum(s2[7]), .cout(c2[7]));
    
    // 第二组处理
    full_adder fa8 (.a(s1[8]), .b(c1[7]), .cin(pp7[0]), .sum(s2[8]), .cout(c2[8]));
    full_adder fa9 (.a(s1[9]), .b(c1[8]), .cin(pp7[1]), .sum(s2[9]), .cout(c2[9]));
    full_adder fa10 (.a(s1[10]), .b(c1[9]), .cin(pp7[2]), .sum(s2[10]), .cout(c2[10]));
    full_adder fa11 (.a(s1[11]), .b(c1[10]), .cin(pp7[3]), .sum(s2[11]), .cout(c2[11]));
    full_adder fa12 (.a(s1[12]), .b(c1[11]), .cin(pp7[4]), .sum(s2[12]), .cout(c2[12]));
    full_adder fa13 (.a(s1[13]), .b(c1[12]), .cin(pp7[5]), .sum(s2[13]), .cout(c2[13]));
    full_adder fa14 (.a(s1[14]), .b(c1[13]), .cin(pp7[6]), .sum(s2[14]), .cout(c2[14]));
endmodule

// 最终加法器阶段模块
module final_adder_stage (
    input wire [14:0] s2,
    input wire [14:0] c2,
    output wire [15:0] product
);
    // 准备最终加法的输入
    wire [15:0] sum, carry;
    
    // 设置初始条件
    assign sum[0] = s2[0];
    assign carry[0] = 1'b0;
    
    // 连接中间结果
    assign sum[1] = s2[1];
    assign carry[1] = c2[0];
    
    // 配置剩余位
    genvar k;
    generate
        for (k = 2; k < 15; k = k + 1) begin: final_adder_prep
            assign sum[k] = s2[k];
            assign carry[k] = c2[k-1];
        end
    endgenerate
    
    // 处理最高位
    assign sum[15] = c2[14];
    assign carry[15] = 1'b0;
    
    // 执行最终加法 (行波进位加法器)
    wire [15:0] temp_carry;
    
    // 最低位处理
    half_adder ha_final (.a(sum[0]), .b(carry[0]), .sum(product[0]), .cout(temp_carry[0]));
    
    // 剩余位处理
    generate
        for (k = 1; k < 16; k = k + 1) begin: final_ripple_adder
            full_adder fa_final (
                .a(sum[k]), 
                .b(carry[k]), 
                .cin(temp_carry[k-1]), 
                .sum(product[k]), 
                .cout(temp_carry[k])
            );
        end
    endgenerate
endmodule

// 全加器模块
module full_adder (
    input wire a, b, cin,
    output wire sum, cout
);
    // 分离和与进位计算以优化时序路径
    wire partial_sum;
    
    assign partial_sum = a ^ b;
    assign sum = partial_sum ^ cin;
    assign cout = (a & b) | (partial_sum & cin);
endmodule

// 半加器模块
module half_adder (
    input wire a, b,
    output wire sum, cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule