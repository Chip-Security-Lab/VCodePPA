//SystemVerilog
module odd_divider #(
    parameter N = 5
)(
    input  wire clk,     // 主时钟输入
    input  wire rst,     // 复位信号，高电平有效
    output wire clk_out  // 分频后的时钟输出
);

    // ====== 内部信号定义 - 重新组织 ======
    // 主计数器路径信号
    reg  [2:0] state_counter;       // 当前状态计数器
    reg  [2:0] next_state_counter;  // 预计算的下一状态

    // 时钟生成路径信号
    reg        phase_pos_clock;     // 正相位时钟信号 (同步于上升沿)
    reg        phase_neg_clock;     // 负相位时钟信号 (同步于下降沿)
    wire       phase_threshold;     // 相位判断阈值
    
    // ====== 数据路径阶段1: 计数器逻辑 ======
    // 预计算下一状态 - 计数器路径
    always @(*) begin
        if (state_counter == N-1)
            next_state_counter = 3'd0;
        else
            next_state_counter = state_counter + 3'd1;
    end

    // 状态寄存器更新 - 同步复位
    always @(posedge clk or posedge rst) begin
        if (rst)
            state_counter <= 3'd0;
        else
            state_counter <= next_state_counter;
    end

    // ====== 数据路径阶段2: 时钟相位生成 ======
    // 计算相位判断阈值
    assign phase_threshold = (N >> 1);
    
    // 生成正相位时钟 - 上升沿触发
    always @(posedge clk or posedge rst) begin
        if (rst)
            phase_pos_clock <= 1'b0;
        else
            phase_pos_clock <= (state_counter < phase_threshold) ? 1'b1 : 1'b0;
    end

    // 生成负相位时钟 - 下降沿触发
    always @(negedge clk or posedge rst) begin
        if (rst)
            phase_neg_clock <= 1'b0;
        else
            phase_neg_clock <= phase_pos_clock;
    end

    // ====== 数据路径阶段3: 输出时钟合成 ======
    // 最终时钟输出 - 组合正负时钟相位
    assign clk_out = phase_pos_clock | phase_neg_clock;

endmodule