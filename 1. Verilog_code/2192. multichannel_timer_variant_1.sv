//SystemVerilog
module multichannel_timer #(
    parameter CHANNELS = 4,
    parameter DATA_WIDTH = 16
)(
    input wire clock,
    input wire reset,
    input wire [CHANNELS-1:0] channel_en,
    input wire [DATA_WIDTH-1:0] timeout_values [CHANNELS-1:0],
    output reg [CHANNELS-1:0] timeout_flags,
    output reg [$clog2(CHANNELS)-1:0] active_channel
);
    // 流水线寄存器
    reg [DATA_WIDTH-1:0] counters [CHANNELS-1:0];
    
    // 阶段1 - 比较逻辑寄存器
    reg [CHANNELS-1:0] compare_results_stage1;
    reg [CHANNELS-1:0] channel_en_stage1;
    reg [$clog2(CHANNELS)-1:0] channel_id_stage1 [CHANNELS-1:0];
    
    // 阶段2 - 优先级编码寄存器
    reg [CHANNELS-1:0] timeout_pending_stage2;
    reg [$clog2(CHANNELS)-1:0] highest_priority_channel_stage2;
    reg timeout_detected_stage2;
    
    // 阶段3 - 计数器更新准备寄存器
    reg [CHANNELS-1:0] counters_reset_stage3;
    reg [CHANNELS-1:0] counters_increment_stage3;
    
    // 并行前缀加法器信号
    wire [DATA_WIDTH-1:0] adder_inputs [CHANNELS-1:0];
    wire [DATA_WIDTH-1:0] adder_outputs [CHANNELS-1:0];
    
    integer i, j;
    
    // 阶段1: 计数器比较逻辑
    // ... existing code ...
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < CHANNELS; i = i + 1) begin
                compare_results_stage1[i] <= 1'b0;
                channel_en_stage1[i] <= 1'b0;
                channel_id_stage1[i] <= i;
            end
        end else begin
            for (i = 0; i < CHANNELS; i = i + 1) begin
                // 保存使能状态和通道ID
                channel_en_stage1[i] <= channel_en[i];
                channel_id_stage1[i] <= i;
                
                // 比较计数器与超时值
                if (channel_en[i] && (counters[i] >= timeout_values[i])) begin
                    compare_results_stage1[i] <= 1'b1;
                end else begin
                    compare_results_stage1[i] <= 1'b0;
                end
            end
        end
    end
    
    // 阶段2: 优先级编码逻辑
    // ... existing code ...
    always @(posedge clock) begin
        if (reset) begin
            timeout_pending_stage2 <= {CHANNELS{1'b0}};
            highest_priority_channel_stage2 <= {$clog2(CHANNELS){1'b0}};
            timeout_detected_stage2 <= 1'b0;
        end else begin
            timeout_pending_stage2 <= compare_results_stage1 & channel_en_stage1;
            timeout_detected_stage2 <= |compare_results_stage1;
            
            // 优先级编码 - 找到最高优先级超时通道
            highest_priority_channel_stage2 <= {$clog2(CHANNELS){1'b0}};
            for (i = 0; i < CHANNELS; i = i + 1) begin
                if (compare_results_stage1[i] && channel_en_stage1[i]) begin
                    highest_priority_channel_stage2 <= channel_id_stage1[i];
                end
            end
        end
    end
    
    // 阶段3: 准备计数器更新
    // ... existing code ...
    always @(posedge clock) begin
        if (reset) begin
            counters_reset_stage3 <= {CHANNELS{1'b0}};
            counters_increment_stage3 <= {CHANNELS{1'b0}};
        end else begin
            for (i = 0; i < CHANNELS; i = i + 1) begin
                // 确定哪些计数器需要重置
                if (timeout_pending_stage2[i]) begin
                    counters_reset_stage3[i] <= 1'b1;
                    counters_increment_stage3[i] <= 1'b0;
                end 
                // 确定哪些计数器需要递增
                else if (channel_en_stage1[i]) begin
                    counters_reset_stage3[i] <= 1'b0;
                    counters_increment_stage3[i] <= 1'b1;
                end
                else begin
                    counters_reset_stage3[i] <= 1'b0;
                    counters_increment_stage3[i] <= 1'b0;
                end
            end
        end
    end
    
    // 准备加法器输入
    genvar g;
    generate
        for (g = 0; g < CHANNELS; g = g + 1) begin : gen_adder_inputs
            assign adder_inputs[g] = counters_increment_stage3[g] ? counters[g] : {DATA_WIDTH{1'b0}};
        end
    endgenerate
    
    // 实例化并行前缀加法器
    generate
        for (g = 0; g < CHANNELS; g = g + 1) begin : gen_prefix_adders
            parallel_prefix_adder #(
                .WIDTH(DATA_WIDTH)
            ) ppa_inst (
                .a(adder_inputs[g]),
                .b(counters_increment_stage3[g] ? 16'h0001 : 16'h0000),
                .sum(adder_outputs[g])
            );
        end
    endgenerate
    
    // 阶段4: 更新计数器和输出
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < CHANNELS; i = i + 1) begin
                counters[i] <= {DATA_WIDTH{1'b0}};
            end
            timeout_flags <= {CHANNELS{1'b0}};
            active_channel <= {$clog2(CHANNELS){1'b0}};
        end else begin
            // 更新计数器
            for (i = 0; i < CHANNELS; i = i + 1) begin
                if (counters_reset_stage3[i]) begin
                    counters[i] <= {DATA_WIDTH{1'b0}};
                end else if (counters_increment_stage3[i]) begin
                    counters[i] <= adder_outputs[i];
                end
            end
            
            // 更新超时标志
            timeout_flags <= timeout_pending_stage2;
            
            // 当检测到超时时更新活动通道
            if (timeout_detected_stage2) begin
                active_channel <= highest_priority_channel_stage2;
            end
        end
    end
endmodule

// 并行前缀加法器(Kogge-Stone算法)
module parallel_prefix_adder #(
    parameter WIDTH = 16
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] sum
);
    // 生成(G)和传播(P)信号
    wire [WIDTH-1:0] g_init, p_init;
    // 各级前缀计算的G和P信号
    wire [WIDTH-1:0] g_stage[0:$clog2(WIDTH)-1];
    wire [WIDTH-1:0] p_stage[0:$clog2(WIDTH)-1];
    
    // 初始G和P信号计算
    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin : gen_init_gp
            assign g_init[i] = a[i] & b[i];
            assign p_init[i] = a[i] | b[i];
        end
    endgenerate
    
    // 第一级预处理
    assign g_stage[0] = g_init;
    assign p_stage[0] = p_init;
    
    // 并行前缀阶段 (Kogge-Stone算法)
    generate
        for (genvar s = 1; s <= $clog2(WIDTH)-1; s = s + 1) begin : prefix_stages
            for (genvar i = 0; i < WIDTH; i = i + 1) begin : prefix_cells
                if (i >= (1 << (s-1))) begin
                    // 计算G = G_i + P_i·G_{i-2^(s-1)}
                    assign g_stage[s][i] = g_stage[s-1][i] | (p_stage[s-1][i] & g_stage[s-1][i - (1 << (s-1))]);
                    // 计算P = P_i·P_{i-2^(s-1)}
                    assign p_stage[s][i] = p_stage[s-1][i] & p_stage[s-1][i - (1 << (s-1))];
                end else begin
                    // 对于低位元素，直接传递
                    assign g_stage[s][i] = g_stage[s-1][i];
                    assign p_stage[s][i] = p_stage[s-1][i];
                end
            end
        end
    endgenerate
    
    // 计算进位信号
    wire [WIDTH:0] carry;
    assign carry[0] = 1'b0; // 初始进位为0
    
    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin : gen_carry
            assign carry[i+1] = g_stage[$clog2(WIDTH)-1][i] | (p_stage[$clog2(WIDTH)-1][i] & carry[0]);
        end
    endgenerate
    
    // 计算最终求和结果
    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin : gen_sum
            assign sum[i] = a[i] ^ b[i] ^ carry[i];
        end
    endgenerate
endmodule