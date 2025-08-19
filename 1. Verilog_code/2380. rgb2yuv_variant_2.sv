//SystemVerilog
module rgb2yuv (
    input wire clk,                // 时钟信号
    input wire rst_n,              // 复位信号，低电平有效
    input wire [7:0] r, g, b,      // RGB输入数据
    input wire valid_in,           // 输入数据有效信号
    input wire ready_out,          // 下游模块准备接收数据信号
    output reg [7:0] y, u, v,      // YUV输出数据
    output reg valid_out,          // 输出数据有效信号
    output wire ready_in           // 模块准备接收数据信号
);
    // 内部信号声明
    wire [15:0] r_y, g_y, b_y, r_u, g_u, b_u, r_v, g_v, b_v;
    wire [15:0] y_sum, u_sum, v_sum;
    wire [15:0] y_offset, u_offset, v_offset;
    reg processing;                // 数据处理状态标志
    
    // 常量定义
    assign y_offset = 16'd128;
    assign u_offset = 16'd128;
    assign v_offset = 16'd128;
    
    // 握手逻辑
    assign ready_in = !processing || ready_out;  // 当未处理数据或下游准备好时可接收新数据
    
    // 处理状态控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processing <= 1'b0;
            valid_out <= 1'b0;
            y <= 8'd0;
            u <= 8'd0;
            v <= 8'd0;
        end else begin
            if (valid_in && ready_in && !processing) begin
                // 接收新数据开始处理
                processing <= 1'b1;
                valid_out <= 1'b1;
                // 直接计算结果
                y <= y_sum[15:8];
                u <= u_sum[15:8];
                v <= v_sum[15:8];
            end else if (valid_out && ready_out) begin
                // 数据已被下游接收
                valid_out <= 1'b0;
                processing <= 1'b0;
            end
        end
    end
    
    // 使用Wallace乘法器计算Y分量
    wallace_mult_8x8 mult_r_y (.a(r), .b(8'd66), .p(r_y));
    wallace_mult_8x8 mult_g_y (.a(g), .b(8'd129), .p(g_y));
    wallace_mult_8x8 mult_b_y (.a(b), .b(8'd25), .p(b_y));
    
    // 使用Wallace乘法器计算U分量
    wallace_mult_8x8 mult_r_u (.a(r), .b(8'd38), .p(r_u));
    wallace_mult_8x8 mult_g_u (.a(g), .b(8'd74), .p(g_u));
    wallace_mult_8x8 mult_b_u (.a(b), .b(8'd112), .p(b_u));
    
    // 使用Wallace乘法器计算V分量
    wallace_mult_8x8 mult_r_v (.a(r), .b(8'd112), .p(r_v));
    wallace_mult_8x8 mult_g_v (.a(g), .b(8'd94), .p(g_v));
    wallace_mult_8x8 mult_b_v (.a(b), .b(8'd18), .p(b_v));
    
    // 求和运算
    assign y_sum = r_y + g_y + b_y + y_offset;
    assign u_sum = b_u - r_u - g_u + u_offset;
    assign v_sum = r_v - g_v - b_v + v_offset;
endmodule

// Wallace树乘法器实现(8位x8位)
module wallace_mult_8x8 (
    input [7:0] a,
    input [7:0] b,
    output [15:0] p
);
    // 部分积生成
    wire [7:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7;
    
    assign pp0 = b[0] ? a : 8'b0;
    assign pp1 = b[1] ? a : 8'b0;
    assign pp2 = b[2] ? a : 8'b0;
    assign pp3 = b[3] ? a : 8'b0;
    assign pp4 = b[4] ? a : 8'b0;
    assign pp5 = b[5] ? a : 8'b0;
    assign pp6 = b[6] ? a : 8'b0;
    assign pp7 = b[7] ? a : 8'b0;
    
    // 第一级Wallace树压缩
    wire [14:0] s1_1, c1_1;
    wire [13:0] s1_2, c1_2;
    
    full_adder fa1_1_0 (.a(pp0[0]), .b(pp1[0]), .cin(pp2[0]), .s(s1_1[0]), .cout(c1_1[0]));
    full_adder fa1_1_1 (.a(pp0[1]), .b(pp1[1]), .cin(pp2[1]), .s(s1_1[1]), .cout(c1_1[1]));
    full_adder fa1_1_2 (.a(pp0[2]), .b(pp1[2]), .cin(pp2[2]), .s(s1_1[2]), .cout(c1_1[2]));
    full_adder fa1_1_3 (.a(pp0[3]), .b(pp1[3]), .cin(pp2[3]), .s(s1_1[3]), .cout(c1_1[3]));
    full_adder fa1_1_4 (.a(pp0[4]), .b(pp1[4]), .cin(pp2[4]), .s(s1_1[4]), .cout(c1_1[4]));
    full_adder fa1_1_5 (.a(pp0[5]), .b(pp1[5]), .cin(pp2[5]), .s(s1_1[5]), .cout(c1_1[5]));
    full_adder fa1_1_6 (.a(pp0[6]), .b(pp1[6]), .cin(pp2[6]), .s(s1_1[6]), .cout(c1_1[6]));
    full_adder fa1_1_7 (.a(pp0[7]), .b(pp1[7]), .cin(pp2[7]), .s(s1_1[7]), .cout(c1_1[7]));
    
    full_adder fa1_2_0 (.a(pp3[0]), .b(pp4[0]), .cin(pp5[0]), .s(s1_2[0]), .cout(c1_2[0]));
    full_adder fa1_2_1 (.a(pp3[1]), .b(pp4[1]), .cin(pp5[1]), .s(s1_2[1]), .cout(c1_2[1]));
    full_adder fa1_2_2 (.a(pp3[2]), .b(pp4[2]), .cin(pp5[2]), .s(s1_2[2]), .cout(c1_2[2]));
    full_adder fa1_2_3 (.a(pp3[3]), .b(pp4[3]), .cin(pp5[3]), .s(s1_2[3]), .cout(c1_2[3]));
    full_adder fa1_2_4 (.a(pp3[4]), .b(pp4[4]), .cin(pp5[4]), .s(s1_2[4]), .cout(c1_2[4]));
    full_adder fa1_2_5 (.a(pp3[5]), .b(pp4[5]), .cin(pp5[5]), .s(s1_2[5]), .cout(c1_2[5]));
    full_adder fa1_2_6 (.a(pp3[6]), .b(pp4[6]), .cin(pp5[6]), .s(s1_2[6]), .cout(c1_2[6]));
    full_adder fa1_2_7 (.a(pp3[7]), .b(pp4[7]), .cin(pp5[7]), .s(s1_2[7]), .cout(c1_2[7]));
    
    // 第二级Wallace树压缩
    wire [14:0] s2_1, c2_1;
    
    assign s1_1[8] = 1'b0;
    assign s1_1[9] = 1'b0;
    assign s1_1[10] = 1'b0;
    assign s1_1[11] = 1'b0;
    assign s1_1[12] = 1'b0;
    assign s1_1[13] = 1'b0;
    assign s1_1[14] = 1'b0;
    
    assign c1_1[8] = 1'b0;
    assign c1_1[9] = 1'b0;
    assign c1_1[10] = 1'b0;
    assign c1_1[11] = 1'b0;
    assign c1_1[12] = 1'b0;
    assign c1_1[13] = 1'b0;
    assign c1_1[14] = 1'b0;
    
    assign s1_2[8] = 1'b0;
    assign s1_2[9] = 1'b0;
    assign s1_2[10] = 1'b0;
    assign s1_2[11] = 1'b0;
    assign s1_2[12] = 1'b0;
    assign s1_2[13] = 1'b0;
    
    assign c1_2[8] = 1'b0;
    assign c1_2[9] = 1'b0;
    assign c1_2[10] = 1'b0;
    assign c1_2[11] = 1'b0;
    assign c1_2[12] = 1'b0;
    assign c1_2[13] = 1'b0;
    
    full_adder fa2_1_0 (.a(s1_1[0]), .b(s1_2[0]), .cin(pp6[0]), .s(s2_1[0]), .cout(c2_1[0]));
    full_adder fa2_1_1 (.a(s1_1[1]), .b(s1_2[1]), .cin(pp6[1]), .s(s2_1[1]), .cout(c2_1[1]));
    full_adder fa2_1_2 (.a(s1_1[2]), .b(s1_2[2]), .cin(pp6[2]), .s(s2_1[2]), .cout(c2_1[2]));
    full_adder fa2_1_3 (.a(s1_1[3]), .b(s1_2[3]), .cin(pp6[3]), .s(s2_1[3]), .cout(c2_1[3]));
    full_adder fa2_1_4 (.a(s1_1[4]), .b(s1_2[4]), .cin(pp6[4]), .s(s2_1[4]), .cout(c2_1[4]));
    full_adder fa2_1_5 (.a(s1_1[5]), .b(s1_2[5]), .cin(pp6[5]), .s(s2_1[5]), .cout(c2_1[5]));
    full_adder fa2_1_6 (.a(s1_1[6]), .b(s1_2[6]), .cin(pp6[6]), .s(s2_1[6]), .cout(c2_1[6]));
    full_adder fa2_1_7 (.a(s1_1[7]), .b(s1_2[7]), .cin(pp6[7]), .s(s2_1[7]), .cout(c2_1[7]));
    
    // 第三级Wallace树压缩
    wire [15:0] s3_1, c3_1;
    
    assign s2_1[8] = 1'b0;
    assign s2_1[9] = 1'b0;
    assign s2_1[10] = 1'b0;
    assign s2_1[11] = 1'b0;
    assign s2_1[12] = 1'b0;
    assign s2_1[13] = 1'b0;
    assign s2_1[14] = 1'b0;
    
    assign c2_1[8] = 1'b0;
    assign c2_1[9] = 1'b0;
    assign c2_1[10] = 1'b0;
    assign c2_1[11] = 1'b0;
    assign c2_1[12] = 1'b0;
    assign c2_1[13] = 1'b0;
    assign c2_1[14] = 1'b0;
    
    full_adder fa3_1_0 (.a(s2_1[0]), .b(c1_1[0]), .cin(c1_2[0]), .s(s3_1[0]), .cout(c3_1[0]));
    full_adder fa3_1_1 (.a(s2_1[1]), .b(c1_1[1]), .cin(c1_2[1]), .s(s3_1[1]), .cout(c3_1[1]));
    full_adder fa3_1_2 (.a(s2_1[2]), .b(c1_1[2]), .cin(c1_2[2]), .s(s3_1[2]), .cout(c3_1[2]));
    full_adder fa3_1_3 (.a(s2_1[3]), .b(c1_1[3]), .cin(c1_2[3]), .s(s3_1[3]), .cout(c3_1[3]));
    full_adder fa3_1_4 (.a(s2_1[4]), .b(c1_1[4]), .cin(c1_2[4]), .s(s3_1[4]), .cout(c3_1[4]));
    full_adder fa3_1_5 (.a(s2_1[5]), .b(c1_1[5]), .cin(c1_2[5]), .s(s3_1[5]), .cout(c3_1[5]));
    full_adder fa3_1_6 (.a(s2_1[6]), .b(c1_1[6]), .cin(c1_2[6]), .s(s3_1[6]), .cout(c3_1[6]));
    full_adder fa3_1_7 (.a(s2_1[7]), .b(c1_1[7]), .cin(c1_2[7]), .s(s3_1[7]), .cout(c3_1[7]));
    full_adder fa3_1_8 (.a(s2_1[8]), .b(c1_1[8]), .cin(c1_2[8]), .s(s3_1[8]), .cout(c3_1[8]));
    
    // 最终级加法：行波进位加法器
    wire [15:0] sum;
    wire [15:0] carry;
    
    assign s3_1[9] = 1'b0;
    assign s3_1[10] = 1'b0;
    assign s3_1[11] = 1'b0;
    assign s3_1[12] = 1'b0;
    assign s3_1[13] = 1'b0;
    assign s3_1[14] = 1'b0;
    assign s3_1[15] = 1'b0;
    
    assign c3_1[9] = 1'b0;
    assign c3_1[10] = 1'b0;
    assign c3_1[11] = 1'b0;
    assign c3_1[12] = 1'b0;
    assign c3_1[13] = 1'b0;
    assign c3_1[14] = 1'b0;
    assign c3_1[15] = 1'b0;
    
    half_adder ha_final_0 (.a(s3_1[0]), .b(pp7[0]), .s(sum[0]), .cout(carry[0]));
    full_adder fa_final_1 (.a(s3_1[1]), .b(pp7[1]), .cin(carry[0]), .s(sum[1]), .cout(carry[1]));
    full_adder fa_final_2 (.a(s3_1[2]), .b(pp7[2]), .cin(carry[1]), .s(sum[2]), .cout(carry[2]));
    full_adder fa_final_3 (.a(s3_1[3]), .b(pp7[3]), .cin(carry[2]), .s(sum[3]), .cout(carry[3]));
    full_adder fa_final_4 (.a(s3_1[4]), .b(pp7[4]), .cin(carry[3]), .s(sum[4]), .cout(carry[4]));
    full_adder fa_final_5 (.a(s3_1[5]), .b(pp7[5]), .cin(carry[4]), .s(sum[5]), .cout(carry[5]));
    full_adder fa_final_6 (.a(s3_1[6]), .b(pp7[6]), .cin(carry[5]), .s(sum[6]), .cout(carry[6]));
    full_adder fa_final_7 (.a(s3_1[7]), .b(pp7[7]), .cin(carry[6]), .s(sum[7]), .cout(carry[7]));
    full_adder fa_final_8 (.a(s3_1[8]), .b(c2_1[7]), .cin(carry[7]), .s(sum[8]), .cout(carry[8]));
    full_adder fa_final_9 (.a(s3_1[9]), .b(c2_1[8]), .cin(carry[8]), .s(sum[9]), .cout(carry[9]));
    full_adder fa_final_10 (.a(s3_1[10]), .b(c3_1[8]), .cin(carry[9]), .s(sum[10]), .cout(carry[10]));
    full_adder fa_final_11 (.a(s3_1[11]), .b(c3_1[9]), .cin(carry[10]), .s(sum[11]), .cout(carry[11]));
    full_adder fa_final_12 (.a(s3_1[12]), .b(c3_1[10]), .cin(carry[11]), .s(sum[12]), .cout(carry[12]));
    full_adder fa_final_13 (.a(s3_1[13]), .b(c3_1[11]), .cin(carry[12]), .s(sum[13]), .cout(carry[13]));
    full_adder fa_final_14 (.a(s3_1[14]), .b(c3_1[12]), .cin(carry[13]), .s(sum[14]), .cout(carry[14]));
    full_adder fa_final_15 (.a(s3_1[15]), .b(c3_1[13]), .cin(carry[14]), .s(sum[15]), .cout());
    
    assign p = sum;
endmodule

// 全加器模块
module full_adder (
    input a, b, cin,
    output s, cout
);
    assign s = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

// 半加器模块
module half_adder (
    input a, b,
    output s, cout
);
    assign s = a ^ b;
    assign cout = a & b;
endmodule