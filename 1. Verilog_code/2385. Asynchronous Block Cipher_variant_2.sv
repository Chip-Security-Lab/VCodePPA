//SystemVerilog
module async_block_cipher #(parameter BLOCK_SIZE = 16) (
    input wire [BLOCK_SIZE-1:0] plaintext, key,
    output wire [BLOCK_SIZE-1:0] ciphertext
);
    wire [BLOCK_SIZE-1:0] intermediate;
    // Layer 1: XOR with key
    assign intermediate = plaintext ^ key;
    // Layer 2: Substitution (non-linear operation)
    genvar i;
    generate
        for (i = 0; i < BLOCK_SIZE/4; i = i + 1) begin : sub_blocks
            kogge_stone_adder #(.WIDTH(4)) ksa_inst (
                .a(intermediate[i*4+:4]),
                .b(intermediate[((i+1)%(BLOCK_SIZE/4))*4+:4]),
                .sum(ciphertext[i*4+:4])
            );
        end
    endgenerate
endmodule

module kogge_stone_adder #(parameter WIDTH = 8) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] sum
);
    // 直接存储进位传播和生成信号
    wire [WIDTH-1:0] p; // 进位传播
    wire [WIDTH-1:0] g; // 进位生成
    
    // 多级并行前缀计算的信号
    wire [WIDTH-1:0] p_stage[0:$clog2(WIDTH)-1];
    wire [WIDTH-1:0] g_stage[0:$clog2(WIDTH)-1];
    
    // 计算初始进位传播和生成信号
    genvar i, j, k;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : pg_gen
            assign p[i] = a[i] ^ b[i];  // 进位传播 = a XOR b
            assign g[i] = a[i] & b[i];  // 进位生成 = a AND b
        end
    endgenerate
    
    // 第一级Kogge-Stone并行前缀 - 直接传递初始值
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : stage0
            assign p_stage[0][i] = p[i];
            assign g_stage[0][i] = g[i];
        end
    endgenerate
    
    // 后续级的Kogge-Stone并行前缀计算
    generate
        for (i = 1; i <= $clog2(WIDTH)-1; i = i + 1) begin : stage_outer
            for (j = 0; j < WIDTH; j = j + 1) begin : stage_inner
                if (j >= (1 << (i-1))) begin
                    // 进位传播规则简化: 两个级联的传播条件必须都满足
                    assign p_stage[i][j] = p_stage[i-1][j] & p_stage[i-1][j-(1<<(i-1))];
                    
                    // 进位生成规则优化: g OR (p AND previous_g)
                    // 使用德摩根定律优化表达式
                    wire temp_and = p_stage[i-1][j] & g_stage[i-1][j-(1<<(i-1))];
                    assign g_stage[i][j] = g_stage[i-1][j] | temp_and;
                end else begin
                    // 对于低位，直接传递前一级的值
                    assign p_stage[i][j] = p_stage[i-1][j];
                    assign g_stage[i][j] = g_stage[i-1][j];
                end
            end
        end
    endgenerate
    
    // 最终求和计算
    generate
        // 最低位是输入的XOR，无需考虑进位
        assign sum[0] = p[0];
        
        // 其他位需要考虑来自Kogge-Stone网络的进位
        for (k = 1; k < WIDTH; k = k + 1) begin : sum_gen
            assign sum[k] = p[k] ^ g_stage[$clog2(WIDTH)-1][k-1];
        end
    endgenerate
endmodule