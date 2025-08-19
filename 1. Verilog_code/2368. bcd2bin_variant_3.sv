//SystemVerilog
module bcd2bin #(parameter N=4)(
    input [N*4-1:0] bcd,
    output [N*7-1:0] bin
);
    genvar i;
    generate 
        for(i=0; i<N; i=i+1) begin: gen_bcd_conversion
            wire [3:0] bcd_digit = bcd[i*4+:4];
            wire [6:0] power_val;
            wire [6:0] result;
            
            // 使用简化的power值分配
            assign power_val = get_power_optimized(i);
            
            wallace_multiplier_8bit mult_inst (
                .a({4'b0000, bcd_digit}),
                .b(power_val),
                .p(result)
            );
            
            assign bin[i*7+:7] = result;
        end
    endgenerate
    
    // 优化的power函数，使用多级条件结构
    function [6:0] get_power_optimized;
        input integer idx;
        reg [6:0] power_result;
        begin
            // 将复杂的case语句转换为多级if-else结构
            if (idx == 0) begin
                power_result = 7'd1;   // 10^0 = 1
            end 
            else if (idx == 1) begin
                power_result = 7'd10;  // 10^1 = 10
            end
            else if (idx == 2) begin
                power_result = 7'd100; // 10^2 = 100
            end
            else begin
                power_result = 7'd0;
            end
            
            get_power_optimized = power_result;
        end
    endfunction
endmodule

module wallace_multiplier_8bit (
    input [7:0] a,
    input [7:0] b,
    output [6:0] p
);
    // 部分积生成
    wire [7:0] pp [7:0];
    wire [7:0] pp_row [7:0]; // 引入中间变量以提高可读性
    genvar i, j;
    
    generate
        for (i = 0; i < 8; i = i + 1) begin: gen_pp_rows
            for (j = 0; j < 8; j = j + 1) begin: gen_pp_cols
                // 分解条件表达式，增加中间信号
                wire a_bit = a[j];
                wire b_bit = b[i];
                assign pp[i][j] = a_bit & b_bit;
                assign pp_row[i][j] = pp[i][j]; // 增加中间变量提高可读性
            end
        end
    endgenerate
    
    // 第一阶段 - 从8行减少到6行
    wire [13:0] s1, c1;
    wire [13:0] sum_stage1, carry_stage1; // 引入有意义的中间变量名
    
    // 第一组：Row 0 + Row 1 + Row 2
    optimized_full_adder fa1_0(pp_row[0][0], pp_row[1][0], pp_row[2][0], s1[0], c1[0]);
    optimized_full_adder fa1_1(pp_row[0][1], pp_row[1][1], pp_row[2][1], s1[1], c1[1]);
    optimized_full_adder fa1_2(pp_row[0][2], pp_row[1][2], pp_row[2][2], s1[2], c1[2]);
    optimized_full_adder fa1_3(pp_row[0][3], pp_row[1][3], pp_row[2][3], s1[3], c1[3]);
    optimized_full_adder fa1_4(pp_row[0][4], pp_row[1][4], pp_row[2][4], s1[4], c1[4]);
    optimized_full_adder fa1_5(pp_row[0][5], pp_row[1][5], pp_row[2][5], s1[5], c1[5]);
    optimized_full_adder fa1_6(pp_row[0][6], pp_row[1][6], pp_row[2][6], s1[6], c1[6]);
    optimized_full_adder fa1_7(pp_row[0][7], pp_row[1][7], pp_row[2][7], s1[7], c1[7]);
    
    // 第二组：Row 3 + Row 4 + Row 5
    optimized_full_adder fa1_8(pp_row[3][0], pp_row[4][0], pp_row[5][0], s1[8], c1[8]);
    optimized_full_adder fa1_9(pp_row[3][1], pp_row[4][1], pp_row[5][1], s1[9], c1[9]);
    optimized_full_adder fa1_10(pp_row[3][2], pp_row[4][2], pp_row[5][2], s1[10], c1[10]);
    optimized_full_adder fa1_11(pp_row[3][3], pp_row[4][3], pp_row[5][3], s1[11], c1[11]);
    optimized_full_adder fa1_12(pp_row[3][4], pp_row[4][4], pp_row[5][4], s1[12], c1[12]);
    optimized_full_adder fa1_13(pp_row[3][5], pp_row[4][5], pp_row[5][5], s1[13], c1[13]);
    
    // 将s1和c1复制到有意义的变量
    assign sum_stage1 = s1;
    assign carry_stage1 = c1;
    
    // 第二阶段 - 从6行减少到4行
    wire [14:0] s2, c2;
    wire [14:0] sum_stage2, carry_stage2; // 引入更有意义的变量名
    
    // 第一组：s1 + c1(移位) + pp6
    optimized_full_adder fa2_0(sum_stage1[0], 1'b0, pp_row[6][0], s2[0], c2[0]);
    optimized_full_adder fa2_1(sum_stage1[1], carry_stage1[0], pp_row[6][1], s2[1], c2[1]);
    optimized_full_adder fa2_2(sum_stage1[2], carry_stage1[1], pp_row[6][2], s2[2], c2[2]);
    optimized_full_adder fa2_3(sum_stage1[3], carry_stage1[2], pp_row[6][3], s2[3], c2[3]);
    optimized_full_adder fa2_4(sum_stage1[4], carry_stage1[3], pp_row[6][4], s2[4], c2[4]);
    optimized_full_adder fa2_5(sum_stage1[5], carry_stage1[4], pp_row[6][5], s2[5], c2[5]);
    optimized_full_adder fa2_6(sum_stage1[6], carry_stage1[5], pp_row[6][6], s2[6], c2[6]);
    optimized_full_adder fa2_7(sum_stage1[7], carry_stage1[6], pp_row[6][7], s2[7], c2[7]);
    
    // 第二组：s1[8:13] + c1[7:12](移位) + pp7
    optimized_full_adder fa2_8(sum_stage1[8], carry_stage1[7], pp_row[7][0], s2[8], c2[8]);
    optimized_full_adder fa2_9(sum_stage1[9], carry_stage1[8], pp_row[7][1], s2[9], c2[9]);
    optimized_full_adder fa2_10(sum_stage1[10], carry_stage1[9], pp_row[7][2], s2[10], c2[10]);
    optimized_full_adder fa2_11(sum_stage1[11], carry_stage1[10], pp_row[7][3], s2[11], c2[11]);
    optimized_full_adder fa2_12(sum_stage1[12], carry_stage1[11], pp_row[7][4], s2[12], c2[12]);
    optimized_full_adder fa2_13(sum_stage1[13], carry_stage1[12], pp_row[7][5], s2[13], c2[13]);
    optimized_full_adder fa2_14(1'b0, carry_stage1[13], pp_row[7][6], s2[14], c2[14]);
    
    // 将s2和c2复制到有意义的变量
    assign sum_stage2 = s2;
    assign carry_stage2 = c2;
    
    // 第三阶段 - 从4行减少到2行
    wire [15:0] s3, c3;
    wire [15:0] sum_stage3, carry_stage3; // 引入更有意义的变量名
    
    // s2 + c2(移位)
    optimized_half_adder ha3_0(sum_stage2[0], 1'b0, s3[0], c3[0]);
    optimized_full_adder fa3_1(sum_stage2[1], carry_stage2[0], 1'b0, s3[1], c3[1]);
    optimized_full_adder fa3_2(sum_stage2[2], carry_stage2[1], 1'b0, s3[2], c3[2]);
    optimized_full_adder fa3_3(sum_stage2[3], carry_stage2[2], 1'b0, s3[3], c3[3]);
    optimized_full_adder fa3_4(sum_stage2[4], carry_stage2[3], 1'b0, s3[4], c3[4]);
    optimized_full_adder fa3_5(sum_stage2[5], carry_stage2[4], 1'b0, s3[5], c3[5]);
    optimized_full_adder fa3_6(sum_stage2[6], carry_stage2[5], 1'b0, s3[6], c3[6]);
    optimized_full_adder fa3_7(sum_stage2[7], carry_stage2[6], 1'b0, s3[7], c3[7]);
    optimized_full_adder fa3_8(sum_stage2[8], carry_stage2[7], 1'b0, s3[8], c3[8]);
    optimized_full_adder fa3_9(sum_stage2[9], carry_stage2[8], 1'b0, s3[9], c3[9]);
    optimized_full_adder fa3_10(sum_stage2[10], carry_stage2[9], 1'b0, s3[10], c3[10]);
    optimized_full_adder fa3_11(sum_stage2[11], carry_stage2[10], 1'b0, s3[11], c3[11]);
    optimized_full_adder fa3_12(sum_stage2[12], carry_stage2[11], 1'b0, s3[12], c3[12]);
    optimized_full_adder fa3_13(sum_stage2[13], carry_stage2[12], 1'b0, s3[13], c3[13]);
    optimized_full_adder fa3_14(sum_stage2[14], carry_stage2[13], pp_row[7][7], s3[14], c3[14]);
    optimized_half_adder ha3_15(1'b0, carry_stage2[14], s3[15], c3[15]);
    
    // 将s3和c3复制到有意义的变量
    assign sum_stage3 = s3;
    assign carry_stage3 = c3;
    
    // 最终阶段 - 进位传播加法器
    wire [15:0] final_sum;
    wire [16:0] final_carry;
    
    assign final_carry[0] = 1'b0;
    
    generate
        for (i = 0; i < 16; i = i + 1) begin: gen_final_adder
            wire sum_bit, carry_bit, a_bit, b_bit, cin_bit;
            
            // 使用中间变量提高可读性
            assign a_bit = sum_stage3[i];
            assign b_bit = carry_stage3[i];
            assign cin_bit = final_carry[i];
            
            optimized_full_adder fa_final(a_bit, b_bit, cin_bit, sum_bit, carry_bit);
            
            assign final_sum[i] = sum_bit;
            assign final_carry[i+1] = carry_bit;
        end
    endgenerate
    
    // 取低7位作为结果
    assign p = final_sum[6:0];
endmodule

// 优化的全加器，通过引入中间变量分解逻辑
module optimized_full_adder(
    input a, b, cin,
    output sum, cout
);
    wire xor_ab;
    wire and_ab;
    wire and_bcin;
    wire and_acin;
    
    // 使用中间变量分解复杂表达式
    assign xor_ab = a ^ b;
    assign sum = xor_ab ^ cin;
    
    assign and_ab = a & b;
    assign and_bcin = b & cin;
    assign and_acin = a & cin;
    
    // 使用中间变量构建进位逻辑
    assign cout = and_ab | and_bcin | and_acin;
endmodule

// 优化的半加器，通过引入中间变量提高清晰度
module optimized_half_adder(
    input a, b,
    output sum, cout
);
    // 使用中间变量分解逻辑
    wire xor_result;
    wire and_result;
    
    assign xor_result = a ^ b;
    assign and_result = a & b;
    
    assign sum = xor_result;
    assign cout = and_result;
endmodule