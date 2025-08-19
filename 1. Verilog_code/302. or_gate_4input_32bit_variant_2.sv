//SystemVerilog
// 顶层模块
module han_carlson_adder_32bit (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire cin,
    output wire [31:0] sum,
    output wire cout
);
    // 内部信号
    wire [31:0] p, g; // 生成和传播信号
    wire [31:0] pp, gg; // 预处理后的生成和传播信号
    wire [31:0] c; // 进位信号

    // 第一阶段：预处理，生成初始的传播和生成信号
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_pg
            assign p[i] = a[i] ^ b[i];
            assign g[i] = a[i] & b[i];
        end
    endgenerate

    // 处理初始进位
    assign pp[0] = p[0];
    assign gg[0] = g[0] | (p[0] & cin);
    
    // 复制其余位的p和g信号
    generate
        for (i = 1; i < 32; i = i + 1) begin : copy_pg
            assign pp[i] = p[i];
            assign gg[i] = g[i];
        end
    endgenerate

    // Han-Carlson并行前缀树 - 处理偶数位
    wire [31:0] p_even, g_even;
    wire [31:0] p_odd, g_odd;
    
    // 分离奇偶位
    generate
        for (i = 0; i < 32; i = i + 2) begin : gen_even
            assign p_even[i/2] = pp[i];
            assign g_even[i/2] = gg[i];
        end
        for (i = 1; i < 32; i = i + 2) begin : gen_odd
            assign p_odd[i/2] = pp[i];
            assign g_odd[i/2] = gg[i];
        end
    endgenerate

    // 对偶数位进行并行前缀计算
    wire [15:0] p_stage [0:4]; // log2(16) = 4级
    wire [15:0] g_stage [0:4];
    
    // 初始化第一级
    assign p_stage[0] = p_even;
    assign g_stage[0] = g_even;
    
    // 构建前缀树 - 偶数位
    generate
        // 第1级: 距离1
        for (i = 0; i < 15; i = i + 1) begin : stage1
            gray_cell gc1 (
                .p_i(p_stage[0][i+1]),
                .g_i(g_stage[0][i+1]),
                .g_k(g_stage[0][i]),
                .g_o(g_stage[1][i+1])
            );
            black_cell bc1 (
                .p_i(p_stage[0][i+1]),
                .g_i(g_stage[0][i+1]),
                .p_k(p_stage[0][i]),
                .g_k(g_stage[0][i]),
                .p_o(p_stage[1][i+1]),
                .g_o()
            );
        end
        assign p_stage[1][0] = p_stage[0][0];
        assign g_stage[1][0] = g_stage[0][0];
        
        // 第2级: 距离2
        for (i = 0; i < 14; i = i + 1) begin : stage2
            gray_cell gc2 (
                .p_i(p_stage[1][i+2]),
                .g_i(g_stage[1][i+2]),
                .g_k(g_stage[1][i]),
                .g_o(g_stage[2][i+2])
            );
            black_cell bc2 (
                .p_i(p_stage[1][i+2]),
                .g_i(g_stage[1][i+2]),
                .p_k(p_stage[1][i]),
                .g_k(g_stage[1][i]),
                .p_o(p_stage[2][i+2]),
                .g_o()
            );
        end
        for (i = 0; i < 2; i = i + 1) begin : copy_stage2
            assign p_stage[2][i] = p_stage[1][i];
            assign g_stage[2][i] = g_stage[1][i];
        end
        
        // 第3级: 距离4
        for (i = 0; i < 12; i = i + 1) begin : stage3
            gray_cell gc3 (
                .p_i(p_stage[2][i+4]),
                .g_i(g_stage[2][i+4]),
                .g_k(g_stage[2][i]),
                .g_o(g_stage[3][i+4])
            );
            black_cell bc3 (
                .p_i(p_stage[2][i+4]),
                .g_i(g_stage[2][i+4]),
                .p_k(p_stage[2][i]),
                .g_k(g_stage[2][i]),
                .p_o(p_stage[3][i+4]),
                .g_o()
            );
        end
        for (i = 0; i < 4; i = i + 1) begin : copy_stage3
            assign p_stage[3][i] = p_stage[2][i];
            assign g_stage[3][i] = g_stage[2][i];
        end
        
        // 第4级: 距离8
        for (i = 0; i < 8; i = i + 1) begin : stage4
            gray_cell gc4 (
                .p_i(p_stage[3][i+8]),
                .g_i(g_stage[3][i+8]),
                .g_k(g_stage[3][i]),
                .g_o(g_stage[4][i+8])
            );
            black_cell bc4 (
                .p_i(p_stage[3][i+8]),
                .g_i(g_stage[3][i+8]),
                .p_k(p_stage[3][i]),
                .g_k(g_stage[3][i]),
                .p_o(p_stage[4][i+8]),
                .g_o()
            );
        end
        for (i = 0; i < 8; i = i + 1) begin : copy_stage4
            assign p_stage[4][i] = p_stage[3][i];
            assign g_stage[4][i] = g_stage[3][i];
        end
    endgenerate
    
    // 计算奇数位的进位
    wire [15:0] p_odd_out, g_odd_out;
    
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_odd_carry
            gray_cell gc_odd (
                .p_i(p_odd[i]),
                .g_i(g_odd[i]),
                .g_k(g_stage[4][i]),
                .g_o(g_odd_out[i])
            );
            assign p_odd_out[i] = p_odd[i];
        end
    endgenerate
    
    // 合并奇偶位结果
    generate
        for (i = 0; i < 16; i = i + 1) begin : merge_results
            assign c[i*2] = g_stage[4][i];
            assign c[i*2+1] = g_odd_out[i];
        end
    endgenerate
    
    // 最终计算和
    generate
        assign sum[0] = p[0] ^ cin;
        for (i = 1; i < 32; i = i + 1) begin : final_sum
            assign sum[i] = p[i] ^ c[i-1];
        end
    endgenerate
    
    // 输出进位
    assign cout = c[31];
endmodule

// 灰色单元 - 只传播生成信号
module gray_cell (
    input wire p_i,
    input wire g_i,
    input wire g_k,
    output wire g_o
);
    assign g_o = g_i | (p_i & g_k);
endmodule

// 黑色单元 - 传播生成和传播信号
module black_cell (
    input wire p_i,
    input wire g_i,
    input wire p_k,
    input wire g_k,
    output wire p_o,
    output wire g_o
);
    assign p_o = p_i & p_k;
    assign g_o = g_i | (p_i & g_k);
endmodule