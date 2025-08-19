//SystemVerilog
module nibble_rotation_shifter (
    input  [15:0] data,
    input  [1:0]  nibble_sel,         // 00=all, 01=upper byte, 10=lower byte, 11=specific nibble
    input  [1:0]  specific_nibble,    // Used when nibble_sel=11
    input  [1:0]  rotate_amount,
    output [15:0] result
);

//-------------------------------------------
// 分解数据为nibble
//-------------------------------------------
wire [3:0] nibble0;
wire [3:0] nibble1;
wire [3:0] nibble2;
wire [3:0] nibble3;

assign nibble0 = data[3:0];
assign nibble1 = data[7:4];
assign nibble2 = data[11:8];
assign nibble3 = data[15:12];

//-------------------------------------------
// 旋转nibble0
//-------------------------------------------
reg [3:0] rotated_nibble0;
always @(*) begin // 旋转nibble0
    case (rotate_amount)
        2'b00: rotated_nibble0 = nibble0;
        2'b01: rotated_nibble0 = {nibble0[2:0], nibble0[3]};
        2'b10: rotated_nibble0 = {nibble0[1:0], nibble0[3:2]};
        2'b11: rotated_nibble0 = {nibble0[0], nibble0[3:1]};
        default: rotated_nibble0 = nibble0;
    endcase
end

//-------------------------------------------
// 旋转nibble1
//-------------------------------------------
reg [3:0] rotated_nibble1;
always @(*) begin // 旋转nibble1
    case (rotate_amount)
        2'b00: rotated_nibble1 = nibble1;
        2'b01: rotated_nibble1 = {nibble1[2:0], nibble1[3]};
        2'b10: rotated_nibble1 = {nibble1[1:0], nibble1[3:2]};
        2'b11: rotated_nibble1 = {nibble1[0], nibble1[3:1]};
        default: rotated_nibble1 = nibble1;
    endcase
end

//-------------------------------------------
// 旋转nibble2
//-------------------------------------------
reg [3:0] rotated_nibble2;
always @(*) begin // 旋转nibble2
    case (rotate_amount)
        2'b00: rotated_nibble2 = nibble2;
        2'b01: rotated_nibble2 = {nibble2[2:0], nibble2[3]};
        2'b10: rotated_nibble2 = {nibble2[1:0], nibble2[3:2]};
        2'b11: rotated_nibble2 = {nibble2[0], nibble2[3:1]};
        default: rotated_nibble2 = nibble2;
    endcase
end

//-------------------------------------------
// 旋转nibble3
//-------------------------------------------
reg [3:0] rotated_nibble3;
always @(*) begin // 旋转nibble3
    case (rotate_amount)
        2'b00: rotated_nibble3 = nibble3;
        2'b01: rotated_nibble3 = {nibble3[2:0], nibble3[3]};
        2'b10: rotated_nibble3 = {nibble3[1:0], nibble3[3:2]};
        2'b11: rotated_nibble3 = {nibble3[0], nibble3[3:1]};
        default: rotated_nibble3 = nibble3;
    endcase
end

//-------------------------------------------
// 根据nibble_sel选择最终输出
//-------------------------------------------
reg [15:0] result_reg;

// 功能：处理nibble_sel为00, 01, 10的情况
always @(*) begin
    case (nibble_sel)
        2'b00: result_reg = {rotated_nibble3, rotated_nibble2, rotated_nibble1, rotated_nibble0};
        2'b01: result_reg = {rotated_nibble3, rotated_nibble2, nibble1, nibble0};
        2'b10: result_reg = {nibble3, nibble2, rotated_nibble1, rotated_nibble0};
        default: result_reg = data;
    endcase
end

// 功能：处理nibble_sel为11（specific nibble）的情况
reg [15:0] specific_nibble_result;
always @(*) begin
    case (specific_nibble)
        2'b00: specific_nibble_result = {nibble3, nibble2, nibble1, rotated_nibble0};
        2'b01: specific_nibble_result = {nibble3, nibble2, rotated_nibble1, nibble0};
        2'b10: specific_nibble_result = {nibble3, rotated_nibble2, nibble1, nibble0};
        2'b11: specific_nibble_result = {rotated_nibble3, nibble2, nibble1, nibble0};
        default: specific_nibble_result = data;
    endcase
end

//-------------------------------------------
// 最终结果输出
//-------------------------------------------
assign result = (nibble_sel == 2'b11) ? specific_nibble_result : result_reg;

endmodule

//==================================================================
// 16x16 Dadda乘法器模块(可复用)
//==================================================================
module dadda_multiplier_16x16 (
    input  [15:0] multiplicand,
    input  [15:0] multiplier,
    output [31:0] product
);
    // Partial Product Generation
    wire [15:0] pp [15:0];
    genvar i, j;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_pp_rows
            for (j = 0; j < 16; j = j + 1) begin : gen_pp_cols
                assign pp[i][j] = multiplicand[j] & multiplier[i];
            end
        end
    endgenerate

    // Dadda reduction tree wires
    wire [31:0] sum_stage [0:5];
    wire [31:0] carry_stage [0:5];

    // Stage 0: Partial product array to sum/carry
    wire [31:0] pp_array;
    assign pp_array[0]  = pp[0][0];
    assign pp_array[1]  = pp[0][1]  ^ pp[1][0];
    assign pp_array[2]  = pp[0][2]  ^ pp[1][1]  ^ pp[2][0];
    assign pp_array[3]  = pp[0][3]  ^ pp[1][2]  ^ pp[2][1]  ^ pp[3][0];
    assign pp_array[4]  = pp[0][4]  ^ pp[1][3]  ^ pp[2][2]  ^ pp[3][1]  ^ pp[4][0];
    assign pp_array[5]  = pp[0][5]  ^ pp[1][4]  ^ pp[2][3]  ^ pp[3][2]  ^ pp[4][1]  ^ pp[5][0];
    assign pp_array[6]  = pp[0][6]  ^ pp[1][5]  ^ pp[2][4]  ^ pp[3][3]  ^ pp[4][2]  ^ pp[5][1]  ^ pp[6][0];
    assign pp_array[7]  = pp[0][7]  ^ pp[1][6]  ^ pp[2][5]  ^ pp[3][4]  ^ pp[4][3]  ^ pp[5][2]  ^ pp[6][1]  ^ pp[7][0];
    assign pp_array[8]  = pp[0][8]  ^ pp[1][7]  ^ pp[2][6]  ^ pp[3][5]  ^ pp[4][4]  ^ pp[5][3]  ^ pp[6][2]  ^ pp[7][1]  ^ pp[8][0];
    assign pp_array[9]  = pp[0][9]  ^ pp[1][8]  ^ pp[2][7]  ^ pp[3][6]  ^ pp[4][5]  ^ pp[5][4]  ^ pp[6][3]  ^ pp[7][2]  ^ pp[8][1]  ^ pp[9][0];
    assign pp_array[10] = pp[0][10] ^ pp[1][9]  ^ pp[2][8]  ^ pp[3][7]  ^ pp[4][6]  ^ pp[5][5]  ^ pp[6][4]  ^ pp[7][3]  ^ pp[8][2]  ^ pp[9][1]  ^ pp[10][0];
    assign pp_array[11] = pp[0][11] ^ pp[1][10] ^ pp[2][9]  ^ pp[3][8]  ^ pp[4][7]  ^ pp[5][6]  ^ pp[6][5]  ^ pp[7][4]  ^ pp[8][3]  ^ pp[9][2]  ^ pp[10][1] ^ pp[11][0];
    assign pp_array[12] = pp[0][12] ^ pp[1][11] ^ pp[2][10] ^ pp[3][9]  ^ pp[4][8]  ^ pp[5][7]  ^ pp[6][6]  ^ pp[7][5]  ^ pp[8][4]  ^ pp[9][3]  ^ pp[10][2] ^ pp[11][1] ^ pp[12][0];
    assign pp_array[13] = pp[0][13] ^ pp[1][12] ^ pp[2][11] ^ pp[3][10] ^ pp[4][9]  ^ pp[5][8]  ^ pp[6][7]  ^ pp[7][6]  ^ pp[8][5]  ^ pp[9][4]  ^ pp[10][3] ^ pp[11][2] ^ pp[12][1] ^ pp[13][0];
    assign pp_array[14] = pp[0][14] ^ pp[1][13] ^ pp[2][12] ^ pp[3][11] ^ pp[4][10] ^ pp[5][9]  ^ pp[6][8]  ^ pp[7][7]  ^ pp[8][6]  ^ pp[9][5]  ^ pp[10][4] ^ pp[11][3] ^ pp[12][2] ^ pp[13][1] ^ pp[14][0];
    assign pp_array[15] = pp[0][15] ^ pp[1][14] ^ pp[2][13] ^ pp[3][12] ^ pp[4][11] ^ pp[5][10] ^ pp[6][9]  ^ pp[7][8]  ^ pp[8][7]  ^ pp[9][6]  ^ pp[10][5] ^ pp[11][4] ^ pp[12][3] ^ pp[13][2] ^ pp[14][1] ^ pp[15][0];
    assign pp_array[16] = pp[1][15] ^ pp[2][14] ^ pp[3][13] ^ pp[4][12] ^ pp[5][11] ^ pp[6][10] ^ pp[7][9]  ^ pp[8][8]  ^ pp[9][7]  ^ pp[10][6] ^ pp[11][5] ^ pp[12][4] ^ pp[13][3] ^ pp[14][2] ^ pp[15][1];
    assign pp_array[17] = pp[2][15] ^ pp[3][14] ^ pp[4][13] ^ pp[5][12] ^ pp[6][11] ^ pp[7][10] ^ pp[8][9]  ^ pp[9][8]  ^ pp[10][7] ^ pp[11][6] ^ pp[12][5] ^ pp[13][4] ^ pp[14][3] ^ pp[15][2];
    assign pp_array[18] = pp[3][15] ^ pp[4][14] ^ pp[5][13] ^ pp[6][12] ^ pp[7][11] ^ pp[8][10] ^ pp[9][9]  ^ pp[10][8] ^ pp[11][7] ^ pp[12][6] ^ pp[13][5] ^ pp[14][4] ^ pp[15][3];
    assign pp_array[19] = pp[4][15] ^ pp[5][14] ^ pp[6][13] ^ pp[7][12] ^ pp[8][11] ^ pp[9][10] ^ pp[10][9] ^ pp[11][8] ^ pp[12][7] ^ pp[13][6] ^ pp[14][5] ^ pp[15][4];
    assign pp_array[20] = pp[5][15] ^ pp[6][14] ^ pp[7][13] ^ pp[8][12] ^ pp[9][11] ^ pp[10][10]^ pp[11][9] ^ pp[12][8] ^ pp[13][7] ^ pp[14][6] ^ pp[15][5];
    assign pp_array[21] = pp[6][15] ^ pp[7][14] ^ pp[8][13] ^ pp[9][12] ^ pp[10][11]^ pp[11][10]^ pp[12][9] ^ pp[13][8] ^ pp[14][7] ^ pp[15][6];
    assign pp_array[22] = pp[7][15] ^ pp[8][14] ^ pp[9][13] ^ pp[10][12]^ pp[11][11]^ pp[12][10]^ pp[13][9] ^ pp[14][8] ^ pp[15][7];
    assign pp_array[23] = pp[8][15] ^ pp[9][14] ^ pp[10][13]^ pp[11][12]^ pp[12][11]^ pp[13][10]^ pp[14][9] ^ pp[15][8];
    assign pp_array[24] = pp[9][15] ^ pp[10][14]^ pp[11][13]^ pp[12][12]^ pp[13][11]^ pp[14][10]^ pp[15][9];
    assign pp_array[25] = pp[10][15]^ pp[11][14]^ pp[12][13]^ pp[13][12]^ pp[14][11]^ pp[15][10];
    assign pp_array[26] = pp[11][15]^ pp[12][14]^ pp[13][13]^ pp[14][12]^ pp[15][11];
    assign pp_array[27] = pp[12][15]^ pp[13][14]^ pp[14][13]^ pp[15][12];
    assign pp_array[28] = pp[13][15]^ pp[14][14]^ pp[15][13];
    assign pp_array[29] = pp[14][15]^ pp[15][14];
    assign pp_array[30] = pp[15][15];
    assign pp_array[31] = 1'b0;

    // Dadda reduction (using Carry Save Adders (CSAs))
    wire [31:0] reduced_sum;
    wire [31:0] reduced_carry;
    dadda_reduce_16x16 u_dadda_reduce (
        .pp_in(pp_array),
        .sum_out(reduced_sum),
        .carry_out(reduced_carry)
    );

    // Final addition (Carry Propagate Adder)
    assign product = reduced_sum + (reduced_carry << 1);

endmodule

//==================================================================
// Dadda reduction tree for 16x16 multiplier
//==================================================================
module dadda_reduce_16x16 (
    input  [31:0] pp_in,
    output [31:0] sum_out,
    output [31:0] carry_out
);
    // For simplicity, use a series of 4:2 compressors and full adders
    // to reduce to two rows. This is a synthesizable and generic approach.
    wire [31:0] s1, c1;
    wire [31:0] s2, c2;
    wire [31:0] s3, c3;

    // First reduction stage
    dadda_csa32 u_csa_0 (
        .a(pp_in),
        .b({1'b0, pp_in[31:1]}),
        .c({2'b0, pp_in[31:2]}),
        .sum(s1),
        .carry(c1)
    );
    // Second reduction stage
    dadda_csa32 u_csa_1 (
        .a(s1),
        .b(c1 << 1),
        .c({3'b0, pp_in[31:3]}),
        .sum(s2),
        .carry(c2)
    );
    // Third reduction stage
    dadda_csa32 u_csa_2 (
        .a(s2),
        .b(c2 << 1),
        .c({4'b0, pp_in[31:4]}),
        .sum(s3),
        .carry(c3)
    );

    assign sum_out   = s3;
    assign carry_out = c3;
endmodule

//==================================================================
// 32bit Carry Save Adder (CSA) for Dadda tree
//==================================================================
module dadda_csa32 (
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,
    output [31:0] sum,
    output [31:0] carry
);
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_csa
            assign sum[i]   = a[i] ^ b[i] ^ c[i];
            assign carry[i] = (a[i] & b[i]) | (a[i] & c[i]) | (b[i] & c[i]);
        end
    endgenerate
endmodule