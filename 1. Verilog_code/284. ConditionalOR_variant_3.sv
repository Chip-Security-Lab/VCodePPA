//SystemVerilog
// SystemVerilog
// 顶层模块
module ConditionalOR(
    input cond,
    input [7:0] mask, data,
    output reg [7:0] result
);
    wire [7:0] masked_data;
    
    // 实例化乘法器子模块（使用Wallace树算法）
    WallaceMultiplier wallace_mult (
        .multiplicand(data),
        .multiplier(mask),
        .product(masked_data)
    );
    
    // 将多路复用器内联到顶层模块中
    always @(*) begin
        if (cond) begin
            result = masked_data;
        end
        else begin
            result = data;
        end
    end
endmodule

// Wallace树乘法器子模块
module WallaceMultiplier(
    input [7:0] multiplicand,
    input [7:0] multiplier,
    output [7:0] product
);
    // 部分积生成
    wire [7:0] pp[7:0];
    
    // 生成部分积
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_pp_rows
            for (j = 0; j < 8; j = j + 1) begin : gen_pp_cols
                assign pp[i][j] = multiplicand[j] & multiplier[i];
            end
        end
    endgenerate
    
    // Wallace树压缩阶段1的中间结果
    wire [13:0] s1, c1;
    
    // 阶段1压缩
    // 第一组3:2压缩
    half_adder ha1_1 (.a(pp[0][0]), .b(pp[1][0]), .sum(s1[0]), .cout(c1[0]));
    full_adder fa1_1 (.a(pp[0][1]), .b(pp[1][1]), .cin(pp[2][0]), .sum(s1[1]), .cout(c1[1]));
    full_adder fa1_2 (.a(pp[0][2]), .b(pp[1][2]), .cin(pp[2][1]), .sum(s1[2]), .cout(c1[2]));
    full_adder fa1_3 (.a(pp[0][3]), .b(pp[1][3]), .cin(pp[2][2]), .sum(s1[3]), .cout(c1[3]));
    full_adder fa1_4 (.a(pp[0][4]), .b(pp[1][4]), .cin(pp[2][3]), .sum(s1[4]), .cout(c1[4]));
    full_adder fa1_5 (.a(pp[0][5]), .b(pp[1][5]), .cin(pp[2][4]), .sum(s1[5]), .cout(c1[5]));
    full_adder fa1_6 (.a(pp[0][6]), .b(pp[1][6]), .cin(pp[2][5]), .sum(s1[6]), .cout(c1[6]));
    full_adder fa1_7 (.a(pp[0][7]), .b(pp[1][7]), .cin(pp[2][6]), .sum(s1[7]), .cout(c1[7]));
    half_adder ha1_2 (.a(pp[3][6]), .b(pp[2][7]), .sum(s1[8]), .cout(c1[8]));
    
    // 第二组3:2压缩
    half_adder ha1_3 (.a(pp[3][0]), .b(pp[4][0]), .sum(s1[9]), .cout(c1[9]));
    full_adder fa1_8 (.a(pp[3][1]), .b(pp[4][1]), .cin(pp[5][0]), .sum(s1[10]), .cout(c1[10]));
    full_adder fa1_9 (.a(pp[3][2]), .b(pp[4][2]), .cin(pp[5][1]), .sum(s1[11]), .cout(c1[11]));
    full_adder fa1_10 (.a(pp[3][3]), .b(pp[4][3]), .cin(pp[5][2]), .sum(s1[12]), .cout(c1[12]));
    full_adder fa1_11 (.a(pp[3][4]), .b(pp[4][4]), .cin(pp[5][3]), .sum(s1[13]), .cout(c1[13]));
    
    // Wallace树压缩阶段2的中间结果
    wire [11:0] s2, c2;
    
    // 阶段2压缩
    half_adder ha2_1 (.a(s1[0]), .b(c1[0]), .sum(s2[0]), .cout(c2[0]));
    full_adder fa2_1 (.a(s1[1]), .b(c1[1]), .cin(s1[9]), .sum(s2[1]), .cout(c2[1]));
    full_adder fa2_2 (.a(s1[2]), .b(c1[2]), .cin(s1[10]), .sum(s2[2]), .cout(c2[2]));
    full_adder fa2_3 (.a(s1[3]), .b(c1[3]), .cin(s1[11]), .sum(s2[3]), .cout(c2[3]));
    full_adder fa2_4 (.a(s1[4]), .b(c1[4]), .cin(s1[12]), .sum(s2[4]), .cout(c2[4]));
    full_adder fa2_5 (.a(s1[5]), .b(c1[5]), .cin(s1[13]), .sum(s2[5]), .cout(c2[5]));
    full_adder fa2_6 (.a(s1[6]), .b(c1[6]), .cin(pp[4][5]), .sum(s2[6]), .cout(c2[6]));
    full_adder fa2_7 (.a(s1[7]), .b(c1[7]), .cin(pp[4][6]), .sum(s2[7]), .cout(c2[7]));
    full_adder fa2_8 (.a(s1[8]), .b(c1[8]), .cin(pp[4][7]), .sum(s2[8]), .cout(c2[8]));
    half_adder ha2_2 (.a(pp[5][6]), .b(pp[6][5]), .sum(s2[9]), .cout(c2[9]));
    half_adder ha2_3 (.a(pp[5][7]), .b(pp[6][6]), .sum(s2[10]), .cout(c2[10]));
    half_adder ha2_4 (.a(pp[7][6]), .b(pp[6][7]), .sum(s2[11]), .cout(c2[11]));
    
    // 最终加法器阶段 - 使用行波进位加法器
    wire [15:0] final_sum, final_carry;
    
    // 组装最终加法器的输入
    assign final_sum[0] = s2[0];
    assign final_sum[1] = s2[1];
    assign final_sum[2] = s2[2];
    assign final_sum[3] = s2[3];
    assign final_sum[4] = s2[4];
    assign final_sum[5] = s2[5];
    assign final_sum[6] = s2[6];
    assign final_sum[7] = s2[7];
    assign final_sum[8] = s2[8];
    assign final_sum[9] = s2[9];
    assign final_sum[10] = s2[10];
    assign final_sum[11] = s2[11];
    assign final_sum[12] = pp[7][5];
    assign final_sum[13] = pp[7][6];
    assign final_sum[14] = pp[7][7];
    assign final_sum[15] = 1'b0;
    
    assign final_carry[0] = 1'b0;
    assign final_carry[1] = c2[0];
    assign final_carry[2] = c2[1];
    assign final_carry[3] = c2[2];
    assign final_carry[4] = c2[3];
    assign final_carry[5] = c2[4];
    assign final_carry[6] = c2[5];
    assign final_carry[7] = c2[6];
    assign final_carry[8] = c2[7];
    assign final_carry[9] = c2[8];
    assign final_carry[10] = c2[9];
    assign final_carry[11] = c2[10];
    assign final_carry[12] = c2[11];
    assign final_carry[13] = 1'b0;
    assign final_carry[14] = 1'b0;
    assign final_carry[15] = 1'b0;
    
    // 最终加法
    wire [15:0] result_full;
    assign result_full = final_sum + {final_carry[14:0], 1'b0};
    
    // 截断到8位输出
    assign product = result_full[7:0];
endmodule

// 半加器模块
module half_adder(
    input a, b,
    output sum, cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule

// 全加器模块
module full_adder(
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule