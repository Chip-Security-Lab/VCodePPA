//SystemVerilog
// 顶层模块
module Conditional_AND (
    input wire sel,
    input wire [7:0] op_a, op_b,
    output wire [7:0] res
);
    // 内部连接信号
    wire [15:0] mult_result;
    reg [7:0] mux_result;
    
    // 子模块实例化
    Wallace_Multiplier wallace_mult (
        .in_a(op_a),
        .in_b(op_b),
        .result(mult_result)
    );
    
    // 替换选择器子模块的实例化，直接在顶层实现
    always @(*) begin
        if (sel) begin
            mux_result = mult_result[7:0]; // 取低8位作为结果
        end else begin
            mux_result = 8'hFF;
        end
    end
    
    // 输出赋值
    assign res = mux_result;
    
endmodule

// Wallace树乘法器子模块
module Wallace_Multiplier (
    input wire [7:0] in_a,
    input wire [7:0] in_b,
    output wire [15:0] result
);
    // 部分积生成
    wire [7:0][7:0] pp; // 8个8位部分积
    
    // 生成部分积
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : pp_gen_i
            for (j = 0; j < 8; j = j + 1) begin : pp_gen_j
                assign pp[i][j] = in_a[j] & in_b[i];
            end
        end
    endgenerate
    
    // 第一层压缩: 将8个部分积压缩成6个
    wire [14:0] s1_0, c1_0;
    FullAdder fa1_0_0(.a(pp[0][0]), .b(pp[1][0]), .cin(pp[2][0]), .sum(s1_0[0]), .cout(c1_0[0]));
    FullAdder fa1_0_1(.a(pp[0][1]), .b(pp[1][1]), .cin(pp[2][1]), .sum(s1_0[1]), .cout(c1_0[1]));
    FullAdder fa1_0_2(.a(pp[0][2]), .b(pp[1][2]), .cin(pp[2][2]), .sum(s1_0[2]), .cout(c1_0[2]));
    FullAdder fa1_0_3(.a(pp[0][3]), .b(pp[1][3]), .cin(pp[2][3]), .sum(s1_0[3]), .cout(c1_0[3]));
    FullAdder fa1_0_4(.a(pp[0][4]), .b(pp[1][4]), .cin(pp[2][4]), .sum(s1_0[4]), .cout(c1_0[4]));
    FullAdder fa1_0_5(.a(pp[0][5]), .b(pp[1][5]), .cin(pp[2][5]), .sum(s1_0[5]), .cout(c1_0[5]));
    FullAdder fa1_0_6(.a(pp[0][6]), .b(pp[1][6]), .cin(pp[2][6]), .sum(s1_0[6]), .cout(c1_0[6]));
    FullAdder fa1_0_7(.a(pp[0][7]), .b(pp[1][7]), .cin(pp[2][7]), .sum(s1_0[7]), .cout(c1_0[7]));
    
    wire [14:0] s1_1, c1_1;
    FullAdder fa1_1_0(.a(pp[3][0]), .b(pp[4][0]), .cin(pp[5][0]), .sum(s1_1[0]), .cout(c1_1[0]));
    FullAdder fa1_1_1(.a(pp[3][1]), .b(pp[4][1]), .cin(pp[5][1]), .sum(s1_1[1]), .cout(c1_1[1]));
    FullAdder fa1_1_2(.a(pp[3][2]), .b(pp[4][2]), .cin(pp[5][2]), .sum(s1_1[2]), .cout(c1_1[2]));
    FullAdder fa1_1_3(.a(pp[3][3]), .b(pp[4][3]), .cin(pp[5][3]), .sum(s1_1[3]), .cout(c1_1[3]));
    FullAdder fa1_1_4(.a(pp[3][4]), .b(pp[4][4]), .cin(pp[5][4]), .sum(s1_1[4]), .cout(c1_1[4]));
    FullAdder fa1_1_5(.a(pp[3][5]), .b(pp[4][5]), .cin(pp[5][5]), .sum(s1_1[5]), .cout(c1_1[5]));
    FullAdder fa1_1_6(.a(pp[3][6]), .b(pp[4][6]), .cin(pp[5][6]), .sum(s1_1[6]), .cout(c1_1[6]));
    FullAdder fa1_1_7(.a(pp[3][7]), .b(pp[4][7]), .cin(pp[5][7]), .sum(s1_1[7]), .cout(c1_1[7]));
    
    // 第二层压缩: 将6个部分积压缩成4个
    wire [14:0] s2_0, c2_0;
    FullAdder fa2_0_0(.a(s1_0[0]), .b(s1_1[0]), .cin(pp[6][0]), .sum(s2_0[0]), .cout(c2_0[0]));
    FullAdder fa2_0_1(.a(s1_0[1]), .b(s1_1[1]), .cin(pp[6][1]), .sum(s2_0[1]), .cout(c2_0[1]));
    FullAdder fa2_0_2(.a(s1_0[2]), .b(s1_1[2]), .cin(pp[6][2]), .sum(s2_0[2]), .cout(c2_0[2]));
    FullAdder fa2_0_3(.a(s1_0[3]), .b(s1_1[3]), .cin(pp[6][3]), .sum(s2_0[3]), .cout(c2_0[3]));
    FullAdder fa2_0_4(.a(s1_0[4]), .b(s1_1[4]), .cin(pp[6][4]), .sum(s2_0[4]), .cout(c2_0[4]));
    FullAdder fa2_0_5(.a(s1_0[5]), .b(s1_1[5]), .cin(pp[6][5]), .sum(s2_0[5]), .cout(c2_0[5]));
    FullAdder fa2_0_6(.a(s1_0[6]), .b(s1_1[6]), .cin(pp[6][6]), .sum(s2_0[6]), .cout(c2_0[6]));
    FullAdder fa2_0_7(.a(s1_0[7]), .b(s1_1[7]), .cin(pp[6][7]), .sum(s2_0[7]), .cout(c2_0[7]));
    
    wire [14:0] s2_1, c2_1;
    FullAdder fa2_1_0(.a(c1_0[0]), .b(c1_1[0]), .cin(pp[7][0]), .sum(s2_1[0]), .cout(c2_1[0]));
    FullAdder fa2_1_1(.a(c1_0[1]), .b(c1_1[1]), .cin(pp[7][1]), .sum(s2_1[1]), .cout(c2_1[1]));
    FullAdder fa2_1_2(.a(c1_0[2]), .b(c1_1[2]), .cin(pp[7][2]), .sum(s2_1[2]), .cout(c2_1[2]));
    FullAdder fa2_1_3(.a(c1_0[3]), .b(c1_1[3]), .cin(pp[7][3]), .sum(s2_1[3]), .cout(c2_1[3]));
    FullAdder fa2_1_4(.a(c1_0[4]), .b(c1_1[4]), .cin(pp[7][4]), .sum(s2_1[4]), .cout(c2_1[4]));
    FullAdder fa2_1_5(.a(c1_0[5]), .b(c1_1[5]), .cin(pp[7][5]), .sum(s2_1[5]), .cout(c2_1[5]));
    FullAdder fa2_1_6(.a(c1_0[6]), .b(c1_1[6]), .cin(pp[7][6]), .sum(s2_1[6]), .cout(c2_1[6]));
    FullAdder fa2_1_7(.a(c1_0[7]), .b(c1_1[7]), .cin(pp[7][7]), .sum(s2_1[7]), .cout(c2_1[7]));
    
    // 第三层压缩: 将4个部分积压缩成2个
    wire [14:0] s3_0, c3_0;
    FullAdder fa3_0_0(.a(s2_0[0]), .b(s2_1[0]), .cin(c2_0[0]), .sum(s3_0[0]), .cout(c3_0[0]));
    FullAdder fa3_0_1(.a(s2_0[1]), .b(s2_1[1]), .cin(c2_0[1]), .sum(s3_0[1]), .cout(c3_0[1]));
    FullAdder fa3_0_2(.a(s2_0[2]), .b(s2_1[2]), .cin(c2_0[2]), .sum(s3_0[2]), .cout(c3_0[2]));
    FullAdder fa3_0_3(.a(s2_0[3]), .b(s2_1[3]), .cin(c2_0[3]), .sum(s3_0[3]), .cout(c3_0[3]));
    FullAdder fa3_0_4(.a(s2_0[4]), .b(s2_1[4]), .cin(c2_0[4]), .sum(s3_0[4]), .cout(c3_0[4]));
    FullAdder fa3_0_5(.a(s2_0[5]), .b(s2_1[5]), .cin(c2_0[5]), .sum(s3_0[5]), .cout(c3_0[5]));
    FullAdder fa3_0_6(.a(s2_0[6]), .b(s2_1[6]), .cin(c2_0[6]), .sum(s3_0[6]), .cout(c3_0[6]));
    FullAdder fa3_0_7(.a(s2_0[7]), .b(s2_1[7]), .cin(c2_0[7]), .sum(s3_0[7]), .cout(c3_0[7]));
    
    // 最终加法器: 组合顶层进位和结果
    wire [15:0] final_sum;
    wire [15:0] temp_c;
    
    assign final_sum[0] = s3_0[0];
    assign temp_c[0] = c3_0[0];
    
    generate
        for (i = 1; i < 8; i = i + 1) begin : final_adder
            FullAdder fa_final(.a(s3_0[i]), .b(c3_0[i-1]), .cin(c2_1[i-1]), 
                               .sum(final_sum[i]), .cout(temp_c[i]));
        end
    endgenerate
    
    // 处理高位
    assign final_sum[8] = temp_c[7] ^ c2_1[7] ^ c3_0[7];
    assign final_sum[9] = 0;
    assign final_sum[10] = 0;
    assign final_sum[11] = 0;
    assign final_sum[12] = 0;
    assign final_sum[13] = 0;
    assign final_sum[14] = 0;
    assign final_sum[15] = 0;
    
    // 结果输出
    assign result = final_sum;
    
endmodule

// 全加器模块
module FullAdder (
    input wire a, b, cin,
    output wire sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule