//SystemVerilog
module UART_Timestamp #(
    parameter TS_WIDTH = 32,
    parameter TS_CLK_HZ = 100_000_000
)(
    input  wire                  clk,            // 时钟输入
    input  wire                  rx_start,       // 接收开始信号
    input  wire                  tx_start,       // 发送开始信号
    output reg  [TS_WIDTH-1:0]   rx_timestamp,   // 接收时间戳输出
    output reg  [TS_WIDTH-1:0]   tx_timestamp,   // 发送时间戳输出
    input  wire                  ts_sync         // 时间同步脉冲
);

    parameter TS_CLK_DIVIDEND = 1_000_000;
    parameter TS_CLK_DIVISOR  = TS_CLK_HZ / TS_CLK_DIVIDEND;

    // =========================
    // Stage 1: 时间基准计数器
    // =========================
    reg [TS_WIDTH-1:0] global_counter_stage1;
    always @(posedge clk) begin
        if (ts_sync)
            global_counter_stage1 <= {TS_WIDTH{1'b0}};
        else
            global_counter_stage1 <= global_counter_stage1 + 1'b1;
    end

    // =========================
    // Stage 2: 计数器流水线寄存器
    // =========================
    reg [TS_WIDTH-1:0] global_counter_stage2;
    always @(posedge clk) begin
        global_counter_stage2 <= global_counter_stage1;
    end

    // =========================
    // Stage 3a: 捕获请求同步 - 接收
    // =========================
    reg rx_start_sync;
    always @(posedge clk) begin
        rx_start_sync <= rx_start;
    end

    // =========================
    // Stage 3b: 捕获请求同步 - 发送
    // =========================
    reg tx_start_sync;
    always @(posedge clk) begin
        tx_start_sync <= tx_start;
    end

    // =========================
    // Stage 4a: 时间戳捕获流水线 - 接收
    // =========================
    reg [TS_WIDTH-1:0] rx_timestamp_stage;
    always @(posedge clk) begin
        if (rx_start_sync)
            rx_timestamp_stage <= global_counter_stage2;
    end

    // =========================
    // Stage 4b: 时间戳捕获流水线 - 发送
    // =========================
    reg [TS_WIDTH-1:0] tx_timestamp_stage;
    always @(posedge clk) begin
        if (tx_start_sync)
            tx_timestamp_stage <= global_counter_stage2;
    end

    // =========================
    // Stage 5a: 时间戳输出寄存器 - 接收
    // =========================
    always @(posedge clk) begin
        rx_timestamp <= rx_timestamp_stage;
    end

    // =========================
    // Stage 5b: 时间戳输出寄存器 - 发送
    // =========================
    always @(posedge clk) begin
        tx_timestamp <= tx_timestamp_stage;
    end

endmodule