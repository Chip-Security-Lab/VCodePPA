//SystemVerilog
module secded_hamming_gen #(parameter DATA_WIDTH = 64) (
    input wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH+7:0] hamming_out  // 64 data + 8 ECC
);
    wire [7:0] parity;

    // Simplified parity calculations using Boolean algebra
    assign parity[0] = ^data_in[1:0]  ^ ^data_in[3:2]  ^ ^data_in[5:4]  ^ ^data_in[7:6]  ^
                       ^data_in[9:8]  ^ ^data_in[11:10]^ ^data_in[13:12]^ ^data_in[15:14]^
                       ^data_in[17:16]^ ^data_in[19:18]^ ^data_in[21:20]^ ^data_in[23:22]^
                       ^data_in[25:24]^ ^data_in[27:26]^ ^data_in[29:28]^ ^data_in[31:30]^
                       ^data_in[33:32]^ ^data_in[35:34]^ ^data_in[37:36]^ ^data_in[39:38]^
                       ^data_in[41:40]^ ^data_in[43:42]^ ^data_in[45:44]^ ^data_in[47:46]^
                       ^data_in[49:48]^ ^data_in[51:50]^ ^data_in[53:52]^ ^data_in[55:54]^
                       ^data_in[57:56]^ ^data_in[59:58]^ ^data_in[61:60]^ ^data_in[63:62];

    assign parity[1] = ^data_in[3:2]  ^ ^data_in[7:6]  ^ ^data_in[11:10]^ ^data_in[15:14]^
                       ^data_in[19:18]^ ^data_in[23:22]^ ^data_in[27:26]^ ^data_in[31:30]^
                       ^data_in[35:34]^ ^data_in[39:38]^ ^data_in[43:42]^ ^data_in[47:46]^
                       ^data_in[51:50]^ ^data_in[55:54]^ ^data_in[59:58]^ ^data_in[63:62] ^
                       ^data_in[1:0]   ^ ^data_in[5:4]  ^ ^data_in[9:8]   ^ ^data_in[13:12]^
                       ^data_in[17:16]^ ^data_in[21:20]^ ^data_in[25:24]^ ^data_in[29:28]^
                       ^data_in[33:32]^ ^data_in[37:36]^ ^data_in[41:40]^ ^data_in[45:44]^
                       ^data_in[49:48]^ ^data_in[53:52]^ ^data_in[57:56]^ ^data_in[61:60];

    assign parity[2] = ^data_in[7:4]  ^ ^data_in[15:12]^ ^data_in[23:20]^ ^data_in[31:28]^
                       ^data_in[39:36]^ ^data_in[47:44]^ ^data_in[55:52]^ ^data_in[63:60] ^
                       ^data_in[3:0]   ^ ^data_in[11:8]  ^ ^data_in[19:16]^ ^data_in[27:24]^
                       ^data_in[35:32]^ ^data_in[43:40]^ ^data_in[51:48]^ ^data_in[59:56];

    assign parity[3] = ^data_in[15:8] ^ ^data_in[31:24] ^ ^data_in[47:40] ^ ^data_in[63:56] ^
                       ^data_in[7:0]  ^ ^data_in[23:16] ^ ^data_in[39:32] ^ ^data_in[55:48];

    assign parity[4] = ^data_in[31:16] ^ ^data_in[63:48] ^ ^data_in[15:0] ^ ^data_in[47:32];

    assign parity[5] = ^data_in[63:32] ^ ^data_in[31:0];

    assign parity[6] = ^data_in[63:1];

    assign parity[7] = ^{data_in, parity[6:0]};

    assign hamming_out = {parity, data_in};
endmodule

// 32位跳跃进位加法器顶层模块
module cla32_adder (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire        carry_in,
    output wire [31:0] sum,
    output wire        carry_out
);
    wire [7:0]  group_generate;
    wire [7:0]  group_propagate;
    wire [7:0]  carry_group;
    wire [31:0] generate_bit;
    wire [31:0] propagate_bit;
    wire [32:0] carry;

    assign carry[0] = carry_in;

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_gp
            assign generate_bit[i]  = operand_a[i] & operand_b[i];
            assign propagate_bit[i] = operand_a[i] ^ operand_b[i];
        end
    endgenerate

    // 8组，每组4位
    genvar g;
    generate
        for (g = 0; g < 8; g = g + 1) begin : gen_group_gp
            assign group_generate[g]  = generate_bit[g*4+3] | (propagate_bit[g*4+3] & generate_bit[g*4+2]) |
                                        (propagate_bit[g*4+3] & propagate_bit[g*4+2] & generate_bit[g*4+1]) |
                                        (propagate_bit[g*4+3] & propagate_bit[g*4+2] & propagate_bit[g*4+1] & generate_bit[g*4]);
            assign group_propagate[g] = propagate_bit[g*4+3] & propagate_bit[g*4+2] &
                                        propagate_bit[g*4+1] & propagate_bit[g*4];
        end
    endgenerate

    // 组进位
    assign carry_group[0] = carry[0];
    assign carry[4]  = group_generate[0] | (group_propagate[0] & carry[0]);
    assign carry_group[1] = carry[4];
    assign carry[8]  = group_generate[1] | (group_propagate[1] & carry[4]);
    assign carry_group[2] = carry[8];
    assign carry[12] = group_generate[2] | (group_propagate[2] & carry[8]);
    assign carry_group[3] = carry[12];
    assign carry[16] = group_generate[3] | (group_propagate[3] & carry[12]);
    assign carry_group[4] = carry[16];
    assign carry[20] = group_generate[4] | (group_propagate[4] & carry[16]);
    assign carry_group[5] = carry[20];
    assign carry[24] = group_generate[5] | (group_propagate[5] & carry[20]);
    assign carry_group[6] = carry[24];
    assign carry[28] = group_generate[6] | (group_propagate[6] & carry[24]);
    assign carry_group[7] = carry[28];

    // 每组内部进位计算
    genvar j;
    generate
        for (j = 0; j < 8; j = j + 1) begin : gen_block_carry
            wire [3:0] g, p;
            assign g = generate_bit[j*4+3:j*4];
            assign p = propagate_bit[j*4+3:j*4];
            assign carry[j*4+1] = g[0] | (p[0] & carry_group[j]);
            assign carry[j*4+2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & carry_group[j]);
            assign carry[j*4+3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & carry_group[j]);
        end
    endgenerate

    // 求和
    genvar k;
    generate
        for (k = 0; k < 32; k = k + 1) begin : gen_sum
            assign sum[k] = propagate_bit[k] ^ carry[k];
        end
    endgenerate

    assign carry_out = group_generate[7] | (group_propagate[7] & carry[28]);
endmodule