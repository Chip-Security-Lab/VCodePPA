//SystemVerilog
module WatchdogController #(
    parameter TIMEOUT = 16'hFFFF
)(
    input  wire       clk,           // 系统时钟
    input  wire       rst_n,         // 低电平有效复位
    input  wire       refresh,       // 看门狗刷新信号
    output wire       system_reset   // 系统复位输出
);
    // =========================================================================
    // 信号定义 - 使用更具描述性的名称并分组相关信号
    // =========================================================================
    // 同步和边沿检测阶段
    reg  [1:0] refresh_sync_pipe;    // 刷新信号同步管道
    wire       refresh_edge;         // 刷新信号边沿检测

    // 计数器数据路径
    reg [15:0] wdt_counter_r;        // 看门狗计数器寄存器
    reg        counter_expired_r;    // 计数器到期状态寄存器
    wire       counter_reload;       // 计数器重载控制信号
    wire       counter_decrement;    // 计数器递减控制信号
    
    // 复位控制路径
    reg        system_reset_r;       // 系统复位寄存器

    // =========================================================================
    // 阶段1: 输入同步与边沿检测
    // =========================================================================
    // 刷新信号同步电路 - 防止亚稳态
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            refresh_sync_pipe <= 2'b00;
        else
            refresh_sync_pipe <= {refresh_sync_pipe[0], refresh};
    end

    // 刷新信号边沿检测
    assign refresh_edge = refresh_sync_pipe[1];

    // =========================================================================
    // 阶段2: 计数器控制逻辑 - 定义明确的控制信号
    // =========================================================================
    // 计数器控制信号生成
    assign counter_reload = refresh_edge;
    assign counter_decrement = ~counter_expired_r & ~counter_reload;

    // =========================================================================
    // 阶段3: 计数器数据路径
    // =========================================================================
    // 计数器逻辑 - 添加额外寄存器级切分长路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wdt_counter_r <= TIMEOUT;
        else if (counter_reload)
            wdt_counter_r <= TIMEOUT;
        else if (counter_decrement)
            wdt_counter_r <= wdt_counter_r - 1'b1;
    end

    // 计数器到期检测 - 分离逻辑以缩短关键路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter_expired_r <= 1'b0;
        else
            counter_expired_r <= (wdt_counter_r == 16'h0001) & counter_decrement;
    end

    // =========================================================================
    // 阶段4: 系统复位控制逻辑
    // =========================================================================
    // 系统复位控制 - 基于计数器状态和刷新事件
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            system_reset_r <= 1'b0;
        else if (counter_reload)
            system_reset_r <= 1'b0;
        else if (counter_expired_r)
            system_reset_r <= 1'b1;
    end

    // 系统复位输出
    assign system_reset = system_reset_r;

endmodule