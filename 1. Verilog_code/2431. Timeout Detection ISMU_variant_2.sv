//SystemVerilog
//IEEE 1364-2005
module timeout_ismu(
    input clk, rst_n,
    input [3:0] irq_in,
    input [3:0] irq_mask,
    input [7:0] timeout_val,
    output reg [3:0] irq_out,
    output reg timeout_flag
);
    // 定义计数器数组
    reg [7:0] counter [3:0];
    
    // 预处理有效中断请求信号 - 减少重复计算
    reg [3:0] irq_active;
    reg [3:0] timeout_reached;

    // 前缀加法器信号定义
    wire [7:0] p_in, g_in;
    wire [7:0] p_stage1, g_stage1;
    wire [7:0] p_stage2, g_stage2;
    wire [7:0] p_stage3, g_stage3;
    wire [7:0] carry;
    wire [7:0] sum;

    // 计数器逻辑 - 分解复杂条件逻辑
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 4; i = i + 1)
                counter[i] <= 8'h0;
            irq_active <= 4'h0;
            timeout_reached <= 4'h0;
        end else begin
            for (i = 0; i < 4; i = i + 1) begin
                // 计算有效中断请求信号
                irq_active[i] <= irq_in[i] && !irq_mask[i];
                
                // 提前计算超时条件，减少后续逻辑层级
                timeout_reached[i] <= (counter[i] >= timeout_val);
                
                // 更新计数器逻辑
                if (irq_in[i] && !irq_mask[i]) begin
                    if (counter[i] < timeout_val)
                        counter[i] <= sum; // 使用并行前缀加法器计算结果
                end else begin
                    counter[i] <= 8'h0;
                end
            end
        end
    end
    
    // 中断输出和超时标志逻辑 - 使用预计算信号减少关键路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_out <= 4'h0;
            timeout_flag <= 1'b0;
        end else begin
            // 使用位运算代替循环，减少逻辑层级
            irq_out <= irq_active & timeout_reached;
            
            // 使用归约运算符代替循环，减少树形结构深度
            timeout_flag <= |(irq_active & timeout_reached);
        end
    end
    
    // 并行前缀加法器实现
    // 第一级：生成初始传播(p)和生成(g)信号
    assign p_in = counter[0]; // 使用第一个计数器作为输入A
    assign g_in = 8'h1;       // 固定加1操作的输入B
    
    // 第二级：计算位传播(p)和生成(g)信号
    assign p_stage1[0] = p_in[0];
    assign g_stage1[0] = g_in[0];
    
    generate
        for (genvar j = 1; j < 8; j = j + 1) begin: stage1_gen
            assign p_stage1[j] = p_in[j];
            assign g_stage1[j] = g_in[j] | (p_in[j] & g_in[j-1]);
        end
    endgenerate
    
    // 第三级：合并相邻位的传播和生成信号
    assign p_stage2[0] = p_stage1[0];
    assign g_stage2[0] = g_stage1[0];
    
    generate
        for (genvar j = 1; j < 8; j = j + 1) begin: stage2_gen
            if (j >= 2) begin
                assign p_stage2[j] = p_stage1[j] & p_stage1[j-2];
                assign g_stage2[j] = g_stage1[j] | (p_stage1[j] & g_stage1[j-2]);
            end else begin
                assign p_stage2[j] = p_stage1[j];
                assign g_stage2[j] = g_stage1[j];
            end
        end
    endgenerate
    
    // 第四级：继续合并
    assign p_stage3[0] = p_stage2[0];
    assign g_stage3[0] = g_stage2[0];
    
    generate
        for (genvar j = 1; j < 8; j = j + 1) begin: stage3_gen
            if (j >= 4) begin
                assign p_stage3[j] = p_stage2[j] & p_stage2[j-4];
                assign g_stage3[j] = g_stage2[j] | (p_stage2[j] & g_stage2[j-4]);
            end else begin
                assign p_stage3[j] = p_stage2[j];
                assign g_stage3[j] = g_stage2[j];
            end
        end
    endgenerate
    
    // 计算进位信号
    assign carry[0] = g_stage3[0];
    
    generate
        for (genvar j = 1; j < 8; j = j + 1) begin: carry_gen
            assign carry[j] = g_stage3[j] | (p_stage3[j] & carry[j-1]);
        end
    endgenerate
    
    // 最终求和
    assign sum[0] = p_in[0] ^ g_in[0];
    
    generate
        for (genvar j = 1; j < 8; j = j + 1) begin: sum_gen
            assign sum[j] = p_in[j] ^ carry[j-1];
        end
    endgenerate
    
endmodule