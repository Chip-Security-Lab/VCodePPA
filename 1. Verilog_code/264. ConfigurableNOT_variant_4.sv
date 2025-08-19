//SystemVerilog
module WallaceTreeMultiplier(
    input logic clk,
    input logic rst_n,
    
    // Input interface
    input logic [7:0] multiplicand,
    input logic [7:0] multiplier,
    input logic valid_in,
    output logic ready_out,
    
    // Output interface
    output logic [15:0] product,
    output logic valid_out,
    input logic ready_in
);
    // Internal signals for handshaking
    logic processing;
    logic result_ready;
    logic [15:0] product_reg;
    
    // Processing state logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processing <= 1'b0;
            result_ready <= 1'b0;
            product_reg <= 16'b0;
        end else begin
            // Start processing when handshake occurs on input
            if (valid_in && ready_out && !processing) begin
                processing <= 1'b1;
                result_ready <= 1'b0;
            end
            // Complete processing (takes one cycle in this design)
            else if (processing && !result_ready) begin
                processing <= 1'b0;
                result_ready <= 1'b1;
                product_reg <= product_comb; // Store computed result
            end
            // Clear result when output handshake occurs
            else if (valid_out && ready_in) begin
                result_ready <= 1'b0;
            end
        end
    end
    
    // Handshaking control
    assign ready_out = !processing && !result_ready;
    assign valid_out = result_ready;
    
    // Output assignment
    assign product = product_reg;
    
    // Combinational multiplication logic
    wire [15:0] product_comb;
    
    // 生成部分积
    wire [7:0][7:0] partial_products;
    
    // 生成所有部分积
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_pp_rows
            for (j = 0; j < 8; j = j + 1) begin : gen_pp_cols
                assign partial_products[i][j] = multiplier[i] & multiplicand[j];
            end
        end
    endgenerate
    
    // Wallace树压缩 - 第一级
    wire [13:0] s1, c1;
    // 第一级压缩部分积 0,1,2
    half_adder ha1_0(partial_products[0][0], partial_products[1][0], s1[0], c1[0]);
    full_adder fa1_0(partial_products[0][1], partial_products[1][1], partial_products[2][0], s1[1], c1[1]);
    full_adder fa1_1(partial_products[0][2], partial_products[1][2], partial_products[2][1], s1[2], c1[2]);
    full_adder fa1_2(partial_products[0][3], partial_products[1][3], partial_products[2][2], s1[3], c1[3]);
    full_adder fa1_3(partial_products[0][4], partial_products[1][4], partial_products[2][3], s1[4], c1[4]);
    full_adder fa1_4(partial_products[0][5], partial_products[1][5], partial_products[2][4], s1[5], c1[5]);
    full_adder fa1_5(partial_products[0][6], partial_products[1][6], partial_products[2][5], s1[6], c1[6]);
    full_adder fa1_6(partial_products[0][7], partial_products[1][7], partial_products[2][6], s1[7], c1[7]);
    half_adder ha1_1(partial_products[3][5], partial_products[2][7], s1[8], c1[8]);
    
    // 第一级压缩部分积 3,4,5
    half_adder ha1_2(partial_products[3][0], partial_products[4][0], s1[9], c1[9]);
    full_adder fa1_7(partial_products[3][1], partial_products[4][1], partial_products[5][0], s1[10], c1[10]);
    full_adder fa1_8(partial_products[3][2], partial_products[4][2], partial_products[5][1], s1[11], c1[11]);
    full_adder fa1_9(partial_products[3][3], partial_products[4][3], partial_products[5][2], s1[12], c1[12]);
    full_adder fa1_10(partial_products[3][4], partial_products[4][4], partial_products[5][3], s1[13], c1[13]);
    
    // 第二级压缩
    wire [13:0] s2, c2;
    half_adder ha2_0(s1[0], 1'b0, s2[0], c2[0]);
    half_adder ha2_1(s1[1], c1[0], s2[1], c2[1]);
    full_adder fa2_0(s1[2], c1[1], partial_products[3][0], s2[2], c2[2]);
    full_adder fa2_1(s1[3], c1[2], s1[9], s2[3], c2[3]);
    full_adder fa2_2(s1[4], c1[3], s1[10], s2[4], c2[4]);
    full_adder fa2_3(s1[5], c1[4], s1[11], s2[5], c2[5]);
    full_adder fa2_4(s1[6], c1[5], s1[12], s2[6], c2[6]);
    full_adder fa2_5(s1[7], c1[6], s1[13], s2[7], c2[7]);
    full_adder fa2_6(s1[8], c1[7], partial_products[4][5], s2[8], c2[8]);
    half_adder ha2_2(partial_products[3][6], partial_products[4][6], s2[9], c2[9]);
    half_adder ha2_3(partial_products[3][7], partial_products[4][7], s2[10], c2[10]);
    
    // 第三级压缩
    wire [13:0] s3, c3;
    half_adder ha3_0(s2[0], 1'b0, s3[0], c3[0]);
    half_adder ha3_1(s2[1], c2[0], s3[1], c3[1]);
    half_adder ha3_2(s2[2], c2[1], s3[2], c3[2]);
    full_adder fa3_0(s2[3], c2[2], c1[9], s3[3], c3[3]);
    full_adder fa3_1(s2[4], c2[3], c1[10], s3[4], c3[4]);
    full_adder fa3_2(s2[5], c2[4], c1[11], s3[5], c3[5]);
    full_adder fa3_3(s2[6], c2[5], c1[12], s3[6], c3[6]);
    full_adder fa3_4(s2[7], c2[6], c1[13], s3[7], c3[7]);
    full_adder fa3_5(s2[8], c2[7], partial_products[5][4], s3[8], c3[8]);
    full_adder fa3_6(s2[9], c2[8], partial_products[5][5], s3[9], c3[9]);
    full_adder fa3_7(s2[10], c2[9], partial_products[5][6], s3[10], c3[10]);
    half_adder ha3_3(partial_products[5][7], c2[10], s3[11], c3[11]);
    
    // 最终级：处理剩余的部分积和进位
    wire [9:0] s4, c4;
    half_adder ha4_0(s3[0], 1'b0, s4[0], c4[0]);
    half_adder ha4_1(s3[1], c3[0], s4[1], c4[1]);
    half_adder ha4_2(s3[2], c3[1], s4[2], c4[2]);
    half_adder ha4_3(s3[3], c3[2], s4[3], c4[3]);
    full_adder fa4_0(s3[4], c3[3], partial_products[6][0], s4[4], c4[4]);
    full_adder fa4_1(s3[5], c3[4], partial_products[6][1], s4[5], c4[5]);
    full_adder fa4_2(s3[6], c3[5], partial_products[6][2], s4[6], c4[6]);
    full_adder fa4_3(s3[7], c3[6], partial_products[6][3], s4[7], c4[7]);
    full_adder fa4_4(s3[8], c3[7], partial_products[6][4], s4[8], c4[8]);
    full_adder fa4_5(s3[9], c3[8], partial_products[6][5], s4[9], c4[9]);
    
    // 最终级进位传播加法器 (使用普通加法)
    assign product_comb[0] = s4[0];
    assign product_comb[1] = s4[1] ^ c4[0];
    assign product_comb[2] = s4[2] ^ c4[1] ^ (s4[1] & c4[0]);
    
    wire [15:3] sum, carry;
    assign sum[3] = s4[3] ^ c4[2] ^ (s4[2] & c4[1] | (s4[1] & c4[0] & c4[1]));
    
    // 处理剩余位
    carry_select_adder csa1(
        {s3[11], s3[10], partial_products[6][7], partial_products[6][6], s4[9], s4[8], s4[7], s4[6], s4[5], s4[4], sum[3]},
        {c3[11], c3[10], c3[9], c4[9], c4[8], c4[7], c4[6], c4[5], c4[4], c4[3], c4[2] & (s4[2] | (s4[1] & c4[0] & c4[1]))},
        product_comb[15:3]
    );
endmodule

// 半加器模块
module half_adder(
    input a,
    input b,
    output sum,
    output cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule

// 全加器模块
module full_adder(
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

// 进位选择加法器 (用于最终阶段的高速加法)
module carry_select_adder(
    input [12:0] a,
    input [12:0] b,
    output [12:0] sum
);
    wire [12:0] temp_sum0, temp_sum1;
    wire [12:0] carry0, carry1;
    
    // 计算carry=0的情况
    assign carry0[0] = 0;
    genvar i;
    generate
        for (i = 0; i < 12; i = i + 1) begin : gen_sum0
            assign temp_sum0[i] = a[i] ^ b[i] ^ carry0[i];
            assign carry0[i+1] = (a[i] & b[i]) | (a[i] & carry0[i]) | (b[i] & carry0[i]);
        end
    endgenerate
    assign temp_sum0[12] = a[12] ^ b[12] ^ carry0[12];
    
    // 计算carry=1的情况
    assign carry1[0] = 1;
    generate
        for (i = 0; i < 12; i = i + 1) begin : gen_sum1
            assign temp_sum1[i] = a[i] ^ b[i] ^ carry1[i];
            assign carry1[i+1] = (a[i] & b[i]) | (a[i] & carry1[i]) | (b[i] & carry1[i]);
        end
    endgenerate
    assign temp_sum1[12] = a[12] ^ b[12] ^ carry1[12];
    
    // 选择正确的结果
    assign sum = carry0[0] ? temp_sum1 : temp_sum0;
endmodule