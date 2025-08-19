//SystemVerilog
// 顶层模块 - 8位Dadda乘法器
module and_gate_8bit_reset (
    input wire [7:0] a,    // 8-bit input A
    input wire [7:0] b,    // 8-bit input B
    input wire rst,        // Reset signal
    output reg [7:0] y     // 8-bit output Y (截取乘法结果的低8位)
);
    wire [15:0] mult_result;  // 完整的乘法结果
    
    // 实例化Dadda乘法器
    dadda_multiplier_8bit dadda_inst (
        .a(a),
        .b(b),
        .y(mult_result)
    );
    
    // 处理重置条件并获取结果的低8位
    always @(*) begin
        y = rst ? 8'b00000000 : mult_result[7:0];
    end
endmodule

// 8位Dadda乘法器
module dadda_multiplier_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [15:0] y
);
    // 部分积生成
    wire [7:0][7:0] pp;  // 存储部分积
    
    // 生成部分积
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_pp_i
            for (j = 0; j < 8; j = j + 1) begin : gen_pp_j
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // Dadda压缩阶段
    // 第一阶段: 从13减少到9
    wire [14:0] s1_1, c1_1;  // 第一阶段输出
    
    // 半加器
    half_adder ha1_1(pp[6][0], pp[5][1], s1_1[0], c1_1[0]);
    half_adder ha1_2(pp[4][3], pp[3][4], s1_1[1], c1_1[1]);
    half_adder ha1_3(pp[7][1], pp[6][2], s1_1[2], c1_1[2]);
    half_adder ha1_4(pp[5][3], pp[4][4], s1_1[3], c1_1[3]);
    half_adder ha1_5(pp[3][5], pp[2][6], s1_1[4], c1_1[4]);
    half_adder ha1_6(pp[7][2], pp[6][3], s1_1[5], c1_1[5]);
    half_adder ha1_7(pp[5][4], pp[4][5], s1_1[6], c1_1[6]);
    half_adder ha1_8(pp[3][6], pp[2][7], s1_1[7], c1_1[7]);
    
    // 全加器
    full_adder fa1_1(pp[7][0], pp[6][1], pp[5][2], s1_1[8], c1_1[8]);
    full_adder fa1_2(pp[4][3], pp[3][4], pp[2][5], s1_1[9], c1_1[9]);
    full_adder fa1_3(pp[1][6], pp[0][7], pp[7][1], s1_1[10], c1_1[10]);
    full_adder fa1_4(pp[6][2], pp[5][3], pp[4][4], s1_1[11], c1_1[11]);
    full_adder fa1_5(pp[3][5], pp[2][6], pp[1][7], s1_1[12], c1_1[12]);
    full_adder fa1_6(pp[7][3], pp[6][4], pp[5][5], s1_1[13], c1_1[13]);
    full_adder fa1_7(pp[4][6], pp[3][7], pp[7][4], s1_1[14], c1_1[14]);
    
    // 第二阶段: 从9减少到6
    wire [14:0] s2_1, c2_1;  // 第二阶段输出
    
    // 第二阶段半加器
    half_adder ha2_1(pp[4][0], pp[3][1], s2_1[0], c2_1[0]);
    half_adder ha2_2(pp[5][0], pp[4][1], s2_1[1], c2_1[1]);
    half_adder ha2_3(pp[3][2], pp[2][3], s2_1[2], c2_1[2]);
    half_adder ha2_4(pp[2][0], pp[1][1], s2_1[3], c2_1[3]);
    half_adder ha2_5(pp[3][0], pp[2][1], s2_1[4], c2_1[4]);
    
    // 第二阶段全加器
    full_adder fa2_1(pp[6][0], pp[5][1], pp[4][2], s2_1[5], c2_1[5]);
    full_adder fa2_2(pp[3][3], pp[2][4], pp[1][5], s2_1[6], c2_1[6]);
    full_adder fa2_3(pp[0][6], s1_1[0], c1_1[0], s2_1[7], c2_1[7]);
    full_adder fa2_4(s1_1[1], s1_1[2], c1_1[1], s2_1[8], c2_1[8]);
    full_adder fa2_5(c1_1[2], s1_1[3], s1_1[4], s2_1[9], c2_1[9]);
    full_adder fa2_6(c1_1[3], c1_1[4], s1_1[5], s2_1[10], c2_1[10]);
    full_adder fa2_7(s1_1[6], s1_1[7], c1_1[5], s2_1[11], c2_1[11]);
    full_adder fa2_8(c1_1[6], c1_1[7], s1_1[8], s2_1[12], c2_1[12]);
    full_adder fa2_9(s1_1[9], c1_1[8], c1_1[9], s2_1[13], c2_1[13]);
    full_adder fa2_10(s1_1[10], s1_1[11], c1_1[10], s2_1[14], c2_1[14]);
    
    // 第三阶段: 从6减少到4
    wire [14:0] s3_1, c3_1;  // 第三阶段输出
    
    // 第三阶段半加器
    half_adder ha3_1(pp[1][0], pp[0][1], s3_1[0], c3_1[0]);
    half_adder ha3_2(s2_1[0], pp[2][2], s3_1[1], c3_1[1]);
    half_adder ha3_3(s2_1[1], s2_1[2], s3_1[2], c3_1[2]);
    half_adder ha3_4(c2_1[0], c2_1[1], s3_1[3], c3_1[3]);
    
    // 第三阶段全加器
    full_adder fa3_1(pp[1][2], pp[0][3], s2_1[3], s3_1[4], c3_1[4]);
    full_adder fa3_2(s2_1[4], s2_1[5], c2_1[2], s3_1[5], c3_1[5]);
    full_adder fa3_3(pp[1][4], pp[0][5], s2_1[6], s3_1[6], c3_1[6]);
    full_adder fa3_4(s2_1[7], c2_1[3], c2_1[5], s3_1[7], c3_1[7]);
    full_adder fa3_5(s2_1[8], s2_1[9], c2_1[6], s3_1[8], c3_1[8]);
    full_adder fa3_6(c2_1[7], c2_1[8], c2_1[9], s3_1[9], c3_1[9]);
    full_adder fa3_7(s2_1[10], s2_1[11], s2_1[12], s3_1[10], c3_1[10]);
    full_adder fa3_8(c2_1[10], c2_1[11], c2_1[12], s3_1[11], c3_1[11]);
    full_adder fa3_9(s2_1[13], s2_1[14], s1_1[12], s3_1[12], c3_1[12]);
    full_adder fa3_10(c2_1[13], c2_1[14], c1_1[11], s3_1[13], c3_1[13]);
    full_adder fa3_11(s1_1[13], s1_1[14], c1_1[12], s3_1[14], c3_1[14]);
    
    // 最终求和阶段 - 使用行进进位加法器(简化表示)
    assign y[0] = pp[0][0];
    assign y[1] = s3_1[0];
    assign y[2] = s3_1[1] ^ c3_1[0];
    wire carry2 = s3_1[1] & c3_1[0];
    
    // 逐位求和并传递进位
    genvar k;
    wire [13:0] carry;
    generate
        for (k = 3; k < 16; k = k + 1) begin : gen_sum
            if (k == 3) begin
                full_adder fa_sum_3(s3_1[2], c3_1[1], carry2, y[k], carry[0]);
            end else if (k == 15) begin
                assign y[k] = c3_1[13] ^ c1_1[13] ^ carry[11];
            end else begin
                full_adder fa_sum_k(s3_1[k-1], c3_1[k-2], carry[k-4], y[k], carry[k-3]);
            end
        end
    endgenerate
endmodule

// 半加器模块
module half_adder (
    input wire a,
    input wire b,
    output wire sum,
    output wire carry
);
    assign sum = a ^ b;
    assign carry = a & b;
endmodule

// 全加器模块
module full_adder (
    input wire a,
    input wire b,
    input wire cin,
    output wire sum,
    output wire cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule