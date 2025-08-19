//SystemVerilog
module wallace_multiplier(
    input wire [7:0] a,
    input wire [7:0] b,
    output reg [15:0] y
);
    // 部分积生成
    wire [7:0][7:0] pp; // 8x8=64位部分积
    
    // 生成部分积
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_pp_i
            for (j = 0; j < 8; j = j + 1) begin : gen_pp_j
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // Wallace树压缩 - 第一阶段
    wire [14:0] s1, c1;
    
    // 第1组: pp[0][7:0], pp[1][7:0], pp[2][7:0]
    full_adder fa1_0(.a(pp[0][0]), .b(pp[1][0]), .cin(pp[2][0]), .sum(s1[0]), .cout(c1[0]));
    full_adder fa1_1(.a(pp[0][1]), .b(pp[1][1]), .cin(pp[2][1]), .sum(s1[1]), .cout(c1[1]));
    full_adder fa1_2(.a(pp[0][2]), .b(pp[1][2]), .cin(pp[2][2]), .sum(s1[2]), .cout(c1[2]));
    full_adder fa1_3(.a(pp[0][3]), .b(pp[1][3]), .cin(pp[2][3]), .sum(s1[3]), .cout(c1[3]));
    full_adder fa1_4(.a(pp[0][4]), .b(pp[1][4]), .cin(pp[2][4]), .sum(s1[4]), .cout(c1[4]));
    full_adder fa1_5(.a(pp[0][5]), .b(pp[1][5]), .cin(pp[2][5]), .sum(s1[5]), .cout(c1[5]));
    full_adder fa1_6(.a(pp[0][6]), .b(pp[1][6]), .cin(pp[2][6]), .sum(s1[6]), .cout(c1[6]));
    full_adder fa1_7(.a(pp[0][7]), .b(pp[1][7]), .cin(pp[2][7]), .sum(s1[7]), .cout(c1[7]));
    
    // 第2组: pp[3][7:0], pp[4][7:0], pp[5][7:0]
    full_adder fa1_8(.a(pp[3][0]), .b(pp[4][0]), .cin(pp[5][0]), .sum(s1[8]), .cout(c1[8]));
    full_adder fa1_9(.a(pp[3][1]), .b(pp[4][1]), .cin(pp[5][1]), .sum(s1[9]), .cout(c1[9]));
    full_adder fa1_10(.a(pp[3][2]), .b(pp[4][2]), .cin(pp[5][2]), .sum(s1[10]), .cout(c1[10]));
    full_adder fa1_11(.a(pp[3][3]), .b(pp[4][3]), .cin(pp[5][3]), .sum(s1[11]), .cout(c1[11]));
    full_adder fa1_12(.a(pp[3][4]), .b(pp[4][4]), .cin(pp[5][4]), .sum(s1[12]), .cout(c1[12]));
    full_adder fa1_13(.a(pp[3][5]), .b(pp[4][5]), .cin(pp[5][5]), .sum(s1[13]), .cout(c1[13]));
    full_adder fa1_14(.a(pp[3][6]), .b(pp[4][6]), .cin(pp[5][6]), .sum(s1[14]), .cout(c1[14]));
    
    // Wallace树压缩 - 第二阶段
    wire [14:0] s2, c2;
    
    // 对第一阶段结果压缩
    half_adder ha2_0(.a(s1[0]), .b(pp[6][0]), .sum(s2[0]), .cout(c2[0]));
    full_adder fa2_1(.a(s1[1]), .b(c1[0]), .cin(pp[6][1]), .sum(s2[1]), .cout(c2[1]));
    full_adder fa2_2(.a(s1[2]), .b(c1[1]), .cin(pp[6][2]), .sum(s2[2]), .cout(c2[2]));
    full_adder fa2_3(.a(s1[3]), .b(c1[2]), .cin(pp[6][3]), .sum(s2[3]), .cout(c2[3]));
    full_adder fa2_4(.a(s1[4]), .b(c1[3]), .cin(pp[6][4]), .sum(s2[4]), .cout(c2[4]));
    full_adder fa2_5(.a(s1[5]), .b(c1[4]), .cin(pp[6][5]), .sum(s2[5]), .cout(c2[5]));
    full_adder fa2_6(.a(s1[6]), .b(c1[5]), .cin(pp[6][6]), .sum(s2[6]), .cout(c2[6]));
    full_adder fa2_7(.a(s1[7]), .b(c1[6]), .cin(pp[6][7]), .sum(s2[7]), .cout(c2[7]));
    full_adder fa2_8(.a(s1[8]), .b(c1[7]), .cin(pp[7][0]), .sum(s2[8]), .cout(c2[8]));
    full_adder fa2_9(.a(s1[9]), .b(c1[8]), .cin(pp[7][1]), .sum(s2[9]), .cout(c2[9]));
    full_adder fa2_10(.a(s1[10]), .b(c1[9]), .cin(pp[7][2]), .sum(s2[10]), .cout(c2[10]));
    full_adder fa2_11(.a(s1[11]), .b(c1[10]), .cin(pp[7][3]), .sum(s2[11]), .cout(c2[11]));
    full_adder fa2_12(.a(s1[12]), .b(c1[11]), .cin(pp[7][4]), .sum(s2[12]), .cout(c2[12]));
    full_adder fa2_13(.a(s1[13]), .b(c1[12]), .cin(pp[7][5]), .sum(s2[13]), .cout(c2[13]));
    full_adder fa2_14(.a(s1[14]), .b(c1[13]), .cin(pp[7][6]), .sum(s2[14]), .cout(c2[14]));
    
    // 最终加法器 (Carry Propagate Adder)
    wire [15:0] sum1, sum2;
    wire [15:0] carry;
    
    // 准备两个操作数
    assign sum1 = {1'b0, pp[7][7], s2[14:0]};
    assign sum2 = {c1[14], c2[14:0], 1'b0};
    
    // 全加器链
    half_adder ha_final0(.a(sum1[0]), .b(sum2[0]), .sum(y[0]), .cout(carry[0]));
    
    genvar k;
    generate
        for (k = 1; k < 16; k = k + 1) begin : gen_final_adder
            full_adder fa_final(.a(sum1[k]), .b(sum2[k]), .cin(carry[k-1]), .sum(y[k]), .cout(carry[k]));
        end
    endgenerate
    
endmodule

// 全加器模块
module full_adder(
    input wire a, b, cin,
    output wire sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

// 半加器模块
module half_adder(
    input wire a, b,
    output wire sum, cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule