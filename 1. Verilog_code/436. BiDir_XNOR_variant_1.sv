//SystemVerilog
module BiDir_XNOR(
    inout [7:0] bus_a, bus_b,
    input dir,
    output [7:0] result
);
    // 内部信号声明
    wire [15:0] mult_result;
    reg [7:0] output_result;
    
    // 使用Dadda乘法器计算
    dadda_multiplier_8bit mult_inst(
        .a(bus_a),
        .b(bus_b),
        .p(mult_result)
    );
    
    // 取乘法结果的低8位作为输出
    always @(*) begin
        output_result = mult_result[7:0];
    end
    
    // 输出驱动逻辑
    assign bus_a = dir ? output_result : 8'hzz;
    assign bus_b = dir ? 8'hzz : output_result;
    
    // 结果输出
    assign result = bus_a;
    
endmodule

// 8位Dadda乘法器实现
module dadda_multiplier_8bit(
    input [7:0] a,
    input [7:0] b,
    output [15:0] p
);
    // 部分积生成
    wire [7:0][7:0] pp;
    
    // 生成64个部分积
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin: gen_pp_i
            for (j = 0; j < 8; j = j + 1) begin: gen_pp_j
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // Dadda归约阶段的中间导线
    // 第一阶段: 从高度8降至6
    wire [14:0] s1, c1;
    // 第二阶段: 从高度6降至4
    wire [14:0] s2, c2;
    // 第三阶段: 从高度4降至3
    wire [14:0] s3, c3;
    // 第四阶段: 从高度3降至2
    wire [15:0] s4, c4;
    
    // 第一阶段归约 (8->6)
    half_adder ha1_1(.a(pp[0][6]), .b(pp[1][5]), .s(s1[0]), .c(c1[0]));
    full_adder fa1_1(.a(pp[0][7]), .b(pp[1][6]), .cin(pp[2][5]), .s(s1[1]), .c(c1[1]));
    half_adder ha1_2(.a(pp[1][7]), .b(pp[2][6]), .s(s1[2]), .c(c1[2]));
    half_adder ha1_3(.a(pp[3][4]), .b(pp[4][3]), .s(s1[3]), .c(c1[3]));
    full_adder fa1_2(.a(pp[2][7]), .b(pp[3][6]), .cin(pp[4][5]), .s(s1[4]), .c(c1[4]));
    full_adder fa1_3(.a(pp[3][7]), .b(pp[4][6]), .cin(pp[5][5]), .s(s1[5]), .c(c1[5]));
    half_adder ha1_4(.a(pp[4][7]), .b(pp[5][6]), .s(s1[6]), .c(c1[6]));
    
    // 第二阶段归约 (6->4)
    half_adder ha2_1(.a(pp[0][4]), .b(pp[1][3]), .s(s2[0]), .c(c2[0]));
    full_adder fa2_1(.a(pp[0][5]), .b(pp[1][4]), .cin(pp[2][3]), .s(s2[1]), .c(c2[1]));
    full_adder fa2_2(.a(pp[2][4]), .b(pp[3][3]), .cin(pp[4][2]), .s(s2[2]), .c(c2[2]));
    full_adder fa2_3(.a(s1[0]), .b(pp[2][4]), .cin(pp[3][3]), .s(s2[3]), .c(c2[3]));
    full_adder fa2_4(.a(s1[1]), .b(s1[3]), .cin(pp[5][2]), .s(s2[4]), .c(c2[4]));
    full_adder fa2_5(.a(s1[2]), .b(c1[0]), .cin(pp[3][5]), .s(s2[5]), .c(c2[5]));
    full_adder fa2_6(.a(c1[1]), .b(s1[4]), .cin(pp[5][4]), .s(s2[6]), .c(c2[6]));
    full_adder fa2_7(.a(c1[2]), .b(s1[5]), .cin(pp[6][4]), .s(s2[7]), .c(c2[7]));
    full_adder fa2_8(.a(c1[4]), .b(s1[6]), .cin(pp[6][5]), .s(s2[8]), .c(c2[8]));
    full_adder fa2_9(.a(c1[5]), .b(pp[5][7]), .cin(pp[6][6]), .s(s2[9]), .c(c2[9]));
    half_adder ha2_2(.a(c1[6]), .b(pp[6][7]), .s(s2[10]), .c(c2[10]));
    
    // 第三阶段归约 (4->3)
    half_adder ha3_1(.a(pp[0][3]), .b(pp[1][2]), .s(s3[0]), .c(c3[0]));
    full_adder fa3_1(.a(s2[0]), .b(pp[2][2]), .cin(pp[3][1]), .s(s3[1]), .c(c3[1]));
    full_adder fa3_2(.a(s2[1]), .b(c2[0]), .cin(pp[3][2]), .s(s3[2]), .c(c3[2]));
    full_adder fa3_3(.a(s2[2]), .b(c2[1]), .cin(pp[5][1]), .s(s3[3]), .c(c3[3]));
    full_adder fa3_4(.a(s2[3]), .b(c2[2]), .cin(pp[4][4]), .s(s3[4]), .c(c3[4]));
    full_adder fa3_5(.a(s2[4]), .b(c2[3]), .cin(pp[6][1]), .s(s3[5]), .c(c3[5]));
    full_adder fa3_6(.a(s2[5]), .b(c2[4]), .cin(pp[6][2]), .s(s3[6]), .c(c3[6]));
    full_adder fa3_7(.a(s2[6]), .b(c2[5]), .cin(pp[6][3]), .s(s3[7]), .c(c3[7]));
    full_adder fa3_8(.a(s2[7]), .b(c2[6]), .cin(pp[7][3]), .s(s3[8]), .c(c3[8]));
    full_adder fa3_9(.a(s2[8]), .b(c2[7]), .cin(pp[7][4]), .s(s3[9]), .c(c3[9]));
    full_adder fa3_10(.a(s2[9]), .b(c2[8]), .cin(pp[7][5]), .s(s3[10]), .c(c3[10]));
    full_adder fa3_11(.a(s2[10]), .b(c2[9]), .cin(pp[7][6]), .s(s3[11]), .c(c3[11]));
    half_adder ha3_2(.a(pp[7][7]), .b(c2[10]), .s(s3[12]), .c(c3[12]));
    
    // 第四阶段归约 (3->2)
    half_adder ha4_1(.a(pp[0][2]), .b(pp[1][1]), .s(s4[0]), .c(c4[0]));
    full_adder fa4_1(.a(s3[0]), .b(pp[2][1]), .cin(pp[3][0]), .s(s4[1]), .c(c4[1]));
    full_adder fa4_2(.a(s3[1]), .b(c3[0]), .cin(pp[4][0]), .s(s4[2]), .c(c4[2]));
    full_adder fa4_3(.a(s3[2]), .b(c3[1]), .cin(pp[5][0]), .s(s4[3]), .c(c4[3]));
    full_adder fa4_4(.a(s3[3]), .b(c3[2]), .cin(pp[6][0]), .s(s4[4]), .c(c4[4]));
    full_adder fa4_5(.a(s3[4]), .b(c3[3]), .cin(pp[7][0]), .s(s4[5]), .c(c4[5]));
    full_adder fa4_6(.a(s3[5]), .b(c3[4]), .cin(pp[7][1]), .s(s4[6]), .c(c4[6]));
    full_adder fa4_7(.a(s3[6]), .b(c3[5]), .cin(pp[7][2]), .s(s4[7]), .c(c4[7]));
    full_adder fa4_8(.a(s3[7]), .b(c3[6]), .cin(c3[7]), .s(s4[8]), .c(c4[8]));
    full_adder fa4_9(.a(s3[8]), .b(c3[8]), .cin(c3[9]), .s(s4[9]), .c(c4[9]));
    full_adder fa4_10(.a(s3[9]), .b(c3[10]), .cin(c3[11]), .s(s4[10]), .c(c4[10]));
    full_adder fa4_11(.a(s3[10]), .b(c3[12]), .cin(1'b0), .s(s4[11]), .c(c4[11]));
    assign s4[12] = s3[11];
    assign c4[12] = 1'b0;
    assign s4[13] = s3[12];
    assign c4[13] = 1'b0;
    
    // 最终的加法结果
    assign p[0] = pp[0][0];
    assign p[1] = s4[0];
    
    // 使用行波进位加法器完成最终的加法
    wire [13:0] sum;
    wire [13:0] carry;
    
    half_adder ha_f0(.a(s4[1]), .b(c4[0]), .s(p[2]), .c(carry[0]));
    full_adder fa_f1(.a(s4[2]), .b(c4[1]), .cin(carry[0]), .s(p[3]), .c(carry[1]));
    full_adder fa_f2(.a(s4[3]), .b(c4[2]), .cin(carry[1]), .s(p[4]), .c(carry[2]));
    full_adder fa_f3(.a(s4[4]), .b(c4[3]), .cin(carry[2]), .s(p[5]), .c(carry[3]));
    full_adder fa_f4(.a(s4[5]), .b(c4[4]), .cin(carry[3]), .s(p[6]), .c(carry[4]));
    full_adder fa_f5(.a(s4[6]), .b(c4[5]), .cin(carry[4]), .s(p[7]), .c(carry[5]));
    full_adder fa_f6(.a(s4[7]), .b(c4[6]), .cin(carry[5]), .s(p[8]), .c(carry[6]));
    full_adder fa_f7(.a(s4[8]), .b(c4[7]), .cin(carry[6]), .s(p[9]), .c(carry[7]));
    full_adder fa_f8(.a(s4[9]), .b(c4[8]), .cin(carry[7]), .s(p[10]), .c(carry[8]));
    full_adder fa_f9(.a(s4[10]), .b(c4[9]), .cin(carry[8]), .s(p[11]), .c(carry[9]));
    full_adder fa_f10(.a(s4[11]), .b(c4[10]), .cin(carry[9]), .s(p[12]), .c(carry[10]));
    full_adder fa_f11(.a(s4[12]), .b(c4[11]), .cin(carry[10]), .s(p[13]), .c(carry[11]));
    full_adder fa_f12(.a(s4[13]), .b(c4[12]), .cin(carry[11]), .s(p[14]), .c(carry[12]));
    half_adder ha_f13(.a(c4[13]), .b(carry[12]), .s(p[15]), .c());
    
endmodule

// 半加器模块
module half_adder(
    input a, b,
    output s, c
);
    assign s = a ^ b;
    assign c = a & b;
endmodule

// 全加器模块
module full_adder(
    input a, b, cin,
    output s, c
);
    assign s = a ^ b ^ cin;
    assign c = (a & b) | (a & cin) | (b & cin);
endmodule