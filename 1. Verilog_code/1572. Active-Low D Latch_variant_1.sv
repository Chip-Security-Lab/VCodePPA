//SystemVerilog
module dadda_multiplier_8bit (
    input wire [7:0] multiplicand,
    input wire [7:0] multiplier,
    input wire clk,
    input wire rst_n,
    output reg [15:0] product
);
    // 生成部分积
    wire [7:0][7:0] pp; // 8个8位的部分积
    
    // 部分积生成
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin: pp_gen_i
            for (j = 0; j < 8; j = j + 1) begin: pp_gen_j
                assign pp[i][j] = multiplier[i] & multiplicand[j];
            end
        end
    endgenerate
    
    // Dadda压缩树 - 高度递减: 8->6->4->3->2
    // 第一级压缩: 8->6
    wire [14:0] s_l1, c_l1;
    
    // 第一级半加器
    half_adder ha_l1_1 (pp[6][0], pp[5][1], s_l1[0], c_l1[0]);
    half_adder ha_l1_2 (pp[4][3], pp[3][4], s_l1[1], c_l1[1]);
    half_adder ha_l1_3 (pp[7][0], pp[6][1], s_l1[2], c_l1[2]);
    half_adder ha_l1_4 (pp[5][2], pp[4][3], s_l1[3], c_l1[3]);
    
    // 第一级全加器
    full_adder fa_l1_1 (pp[7][1], pp[6][2], pp[5][3], s_l1[4], c_l1[4]);
    full_adder fa_l1_2 (pp[4][4], pp[3][5], pp[2][6], s_l1[5], c_l1[5]);
    full_adder fa_l1_3 (pp[7][2], pp[6][3], pp[5][4], s_l1[6], c_l1[6]);
    full_adder fa_l1_4 (pp[4][5], pp[3][6], pp[2][7], s_l1[7], c_l1[7]);
    full_adder fa_l1_5 (pp[7][3], pp[6][4], pp[5][5], s_l1[8], c_l1[8]);
    full_adder fa_l1_6 (pp[4][6], pp[3][7], pp[2][8], s_l1[9], c_l1[9]);
    full_adder fa_l1_7 (pp[7][4], pp[6][5], pp[5][6], s_l1[10], c_l1[10]);
    full_adder fa_l1_8 (pp[7][5], pp[6][6], pp[5][7], s_l1[11], c_l1[11]);
    full_adder fa_l1_9 (pp[7][6], pp[6][7], pp[5][8], s_l1[12], c_l1[12]);
    
    // 第二级压缩: 6->4
    wire [14:0] s_l2, c_l2;
    
    // 第二级半加器和全加器
    half_adder ha_l2_1 (pp[4][0], pp[3][1], s_l2[0], c_l2[0]);
    half_adder ha_l2_2 (pp[2][3], pp[1][4], s_l2[1], c_l2[1]);
    half_adder ha_l2_3 (s_l1[0], pp[4][2], s_l2[2], c_l2[2]);
    
    full_adder fa_l2_1 (pp[5][0], pp[4][1], pp[3][2], s_l2[3], c_l2[3]);
    full_adder fa_l2_2 (pp[2][4], pp[1][5], pp[0][6], s_l2[4], c_l2[4]);
    // ... 更多第二级全加器 ...
    
    // 第三级压缩: 4->3
    wire [14:0] s_l3, c_l3;
    
    // 第三级半加器和全加器
    // ... 第三级压缩逻辑 ...
    
    // 第四级压缩: 3->2
    wire [15:0] s_l4, c_l4;
    
    // 第四级半加器和全加器
    // ... 第四级压缩逻辑 ...
    
    // 最终加法器 - 使用行进进位加法器合并最终两行
    wire [15:0] final_sum;
    wire [15:0] shifted_c_l4;
    
    assign shifted_c_l4 = {c_l4[14:0], 1'b0};
    
    carry_ripple_adder_16bit final_adder (
        .a(s_l4),
        .b(shifted_c_l4),
        .cin(1'b0),
        .sum(final_sum),
        .cout()
    );
    
    // 寄存结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            product <= 16'b0;
        else
            product <= final_sum;
    end
endmodule

// 半加器模块
module half_adder (
    input wire a,
    input wire b,
    output wire sum,
    output wire cout
);
    assign sum = a ^ b;
    assign cout = a & b;
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

// 16位行进位加法器
module carry_ripple_adder_16bit (
    input wire [15:0] a,
    input wire [15:0] b,
    input wire cin,
    output wire [15:0] sum,
    output wire cout
);
    wire [16:0] c;
    assign c[0] = cin;
    
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin: ripple_stage
            assign sum[i] = a[i] ^ b[i] ^ c[i];
            assign c[i+1] = (a[i] & b[i]) | (a[i] & c[i]) | (b[i] & c[i]);
        end
    endgenerate
    
    assign cout = c[16];
endmodule