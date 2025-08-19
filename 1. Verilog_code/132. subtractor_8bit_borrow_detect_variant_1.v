module subtractor_8bit_borrow_detect (
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff,
    output borrow
);

    wire [7:0] b_comp;
    wire [8:0] sum;
    wire [1:0] carry_group0;
    wire [1:0] carry_group1;
    wire [1:0] carry_group2;
    wire [1:0] carry_group3;
    wire [1:0] carry_group4;
    wire [1:0] carry_group5;
    wire [1:0] carry_group6;
    wire [1:0] carry_group7;
    wire [1:0] carry_group8;
    
    // 计算b的补码
    assign b_comp = ~b + 1'b1;
    
    // 计算进位生成和传播
    assign carry_group0 = {1'b0, a[0] & b_comp[0]};
    assign carry_group1 = {a[1] & b_comp[1], a[1] ^ b_comp[1]};
    assign carry_group2 = {a[2] & b_comp[2], a[2] ^ b_comp[2]};
    assign carry_group3 = {a[3] & b_comp[3], a[3] ^ b_comp[3]};
    assign carry_group4 = {a[4] & b_comp[4], a[4] ^ b_comp[4]};
    assign carry_group5 = {a[5] & b_comp[5], a[5] ^ b_comp[5]};
    assign carry_group6 = {a[6] & b_comp[6], a[6] ^ b_comp[6]};
    assign carry_group7 = {a[7] & b_comp[7], a[7] ^ b_comp[7]};
    assign carry_group8 = {1'b0, 1'b0};
    
    // 计算进位
    wire [8:0] carry;
    assign carry[0] = carry_group0[0];
    assign carry[1] = carry_group1[0] | (carry_group1[1] & carry[0]);
    assign carry[2] = carry_group2[0] | (carry_group2[1] & carry[1]);
    assign carry[3] = carry_group3[0] | (carry_group3[1] & carry[2]);
    assign carry[4] = carry_group4[0] | (carry_group4[1] & carry[3]);
    assign carry[5] = carry_group5[0] | (carry_group5[1] & carry[4]);
    assign carry[6] = carry_group6[0] | (carry_group6[1] & carry[5]);
    assign carry[7] = carry_group7[0] | (carry_group7[1] & carry[6]);
    assign carry[8] = carry_group8[0] | (carry_group8[1] & carry[7]);
    
    // 计算和
    assign sum[0] = a[0] ^ b_comp[0] ^ carry[0];
    assign sum[1] = a[1] ^ b_comp[1] ^ carry[1];
    assign sum[2] = a[2] ^ b_comp[2] ^ carry[2];
    assign sum[3] = a[3] ^ b_comp[3] ^ carry[3];
    assign sum[4] = a[4] ^ b_comp[4] ^ carry[4];
    assign sum[5] = a[5] ^ b_comp[5] ^ carry[5];
    assign sum[6] = a[6] ^ b_comp[6] ^ carry[6];
    assign sum[7] = a[7] ^ b_comp[7] ^ carry[7];
    assign sum[8] = carry[8];
    
    // 提取结果和借位
    assign diff = sum[7:0];
    assign borrow = sum[8];
    
endmodule