module subtractor_parallel_prefix (
    input wire [7:0] a,   // 被减数
    input wire [7:0] b,   // 减数
    output wire [7:0] res // 差
);

// 第一级：生成和传播信号计算
wire [7:0] g_stage1, p_stage1;
genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin : gen_pp_stage1
        assign g_stage1[i] = ~a[i] & b[i];
        assign p_stage1[i] = a[i] ^ b[i];
    end
endgenerate

// 第二级：进位计算 - 并行前缀结构
wire [7:0] g_stage2, p_stage2;
wire [7:0] carry;

// 第一层并行前缀
assign g_stage2[0] = g_stage1[0];
assign p_stage2[0] = p_stage1[0];

assign g_stage2[1] = g_stage1[1] | (p_stage1[1] & g_stage1[0]);
assign p_stage2[1] = p_stage1[1] & p_stage1[0];

// 第二层并行前缀
assign g_stage2[2] = g_stage1[2] | (p_stage1[2] & g_stage2[1]);
assign p_stage2[2] = p_stage1[2] & p_stage2[1];

assign g_stage2[3] = g_stage1[3] | (p_stage1[3] & g_stage2[2]);
assign p_stage2[3] = p_stage1[3] & p_stage2[2];

// 第三层并行前缀
assign g_stage2[4] = g_stage1[4] | (p_stage1[4] & g_stage2[3]);
assign p_stage2[4] = p_stage1[4] & p_stage2[3];

assign g_stage2[5] = g_stage1[5] | (p_stage1[5] & g_stage2[4]);
assign p_stage2[5] = p_stage1[5] & p_stage2[4];

// 第四层并行前缀
assign g_stage2[6] = g_stage1[6] | (p_stage1[6] & g_stage2[5]);
assign p_stage2[6] = p_stage1[6] & p_stage2[5];

assign g_stage2[7] = g_stage1[7] | (p_stage1[7] & g_stage2[6]);
assign p_stage2[7] = p_stage1[7] & p_stage2[6];

// 第三级：结果计算
assign carry = g_stage2;
assign res = p_stage1 ^ {carry[6:0], 1'b0};

endmodule