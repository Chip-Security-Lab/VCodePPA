//SystemVerilog
module debounce_ismu #(
    parameter CNT_WIDTH = 4
)(
    input  wire       clk,         // 系统时钟
    input  wire       rst,         // 异步复位
    input  wire [7:0] raw_intr,    // 原始中断输入
    output reg  [7:0] stable_intr  // 稳定后的中断输出
);
    // 输入同步器 - 第一级流水线
    reg [7:0] intr_sync_r1;
    // 输入同步器 - 第二级流水线
    reg [7:0] intr_sync_r2;
    // 中断去抖计数器
    reg [CNT_WIDTH-1:0] debounce_counter [7:0];
    // 预处理的输出信号
    reg [7:0] pre_stable_intr;
    
    // 跳跃进位加法器信号
    wire [CNT_WIDTH-1:0] counter_next [7:0];
    wire [CNT_WIDTH-1:0] carry_generate [7:0];
    wire [CNT_WIDTH-1:0] carry_propagate [7:0];
    wire [CNT_WIDTH:0] carry [7:0];
    
    integer i;
    
    // 输入同步逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            intr_sync_r1 <= 8'h0;
            intr_sync_r2 <= 8'h0;
        end else begin
            // 第一级同步
            intr_sync_r1 <= raw_intr;
            // 第二级同步
            intr_sync_r2 <= intr_sync_r1;
        end
    end
    
    // 为每个计数器生成进位信号
    genvar g;
    generate
        for (g = 0; g < 8; g = g + 1) begin: carry_gen
            // 生成和传播信号
            assign carry_generate[g] = debounce_counter[g] & 1'b1;
            assign carry_propagate[g] = debounce_counter[g] | 1'b1;
            
            // 进位链
            assign carry[g][0] = 1'b1; // 加1操作的初始进位
            
            // 跳跃进位计算
            assign carry[g][1] = carry_generate[g][0] | (carry_propagate[g][0] & carry[g][0]);
            
            // 组合进位计算 - 跳跃进位结构
            for (genvar j = 1; j < CNT_WIDTH; j = j + 1) begin: skip_carry
                assign carry[g][j+1] = carry_generate[g][j] | (carry_propagate[g][j] & carry[g][j]);
            end
            
            // 计算下一个计数器值
            for (genvar k = 0; k < CNT_WIDTH; k = k + 1) begin: sum_calc
                assign counter_next[g][k] = debounce_counter[g][k] ^ carry[g][k];
            end
        end
    endgenerate
    
    // 去抖逻辑和稳定信号生成
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位所有计数器
            for (i = 0; i < 8; i = i + 1)
                debounce_counter[i] <= {CNT_WIDTH{1'b0}};
            
            pre_stable_intr <= 8'h0;
        end else begin
            // 对每个位进行独立去抖处理
            for (i = 0; i < 8; i = i + 1) begin
                // 如果输入变化，重置计数器
                if (intr_sync_r1[i] != intr_sync_r2[i]) begin
                    debounce_counter[i] <= {CNT_WIDTH{1'b0}};
                end
                // 如果输入稳定但计数器未满，使用跳跃进位加法器增加计数器
                else if (debounce_counter[i] < {CNT_WIDTH{1'b1}}) begin
                    debounce_counter[i] <= counter_next[i];
                end
                // 如果计数器满了且同步寄存器1和2相同，更新预处理输出
                else if (intr_sync_r1[i] == intr_sync_r2[i]) begin
                    pre_stable_intr[i] <= intr_sync_r2[i];
                end
            end
        end
    end
    
    // 输出寄存器 - 最终流水线级
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stable_intr <= 8'h0;
        end else begin
            stable_intr <= pre_stable_intr;
        end
    end
    
endmodule