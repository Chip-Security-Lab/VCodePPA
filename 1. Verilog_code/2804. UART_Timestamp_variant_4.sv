//SystemVerilog
module UART_Timestamp #(
    parameter TS_WIDTH = 32,
    parameter TS_CLK_HZ = 100_000_000
)(
    input wire clk,
    input wire rst_n,                    // 异步复位信号，新增
    input wire rx_start,
    input wire tx_start,
    output reg [TS_WIDTH-1:0] rx_timestamp,
    output reg [TS_WIDTH-1:0] tx_timestamp,
    input wire ts_sync
);

// 参数定义
parameter TS_CLK_DIVIDEND = 1_000_000;
parameter TS_CLK_DIVISOR = TS_CLK_HZ / TS_CLK_DIVIDEND;

// 全局计数器流水线第1级
reg [TS_WIDTH-1:0] global_counter_stage1;
reg ts_sync_stage1;
reg rx_start_stage1;
reg tx_start_stage1;

// 全局计数器流水线第2级
reg [TS_WIDTH-1:0] global_counter_stage2;
reg ts_sync_stage2;
reg rx_start_stage2;
reg tx_start_stage2;

// 捕获时间戳流水线第3级
reg [TS_WIDTH-1:0] rx_timestamp_stage3;
reg [TS_WIDTH-1:0] tx_timestamp_stage3;
reg rx_valid_stage3;
reg tx_valid_stage3;

// valid信号链
reg rx_valid_stage1, rx_valid_stage2;
reg tx_valid_stage1, tx_valid_stage2;

// 刷新信号
wire flush_pipeline;
assign flush_pipeline = ts_sync; // ts_sync作为flush

// Stage 1: 输入同步和全局计数器更新
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        global_counter_stage1 <= {TS_WIDTH{1'b0}};
        ts_sync_stage1        <= 1'b0;
        rx_start_stage1       <= 1'b0;
        tx_start_stage1       <= 1'b0;
        rx_valid_stage1       <= 1'b0;
        tx_valid_stage1       <= 1'b0;
    end else begin
        ts_sync_stage1  <= ts_sync;
        rx_start_stage1 <= rx_start;
        tx_start_stage1 <= tx_start;
        rx_valid_stage1 <= rx_start;
        tx_valid_stage1 <= tx_start;
        if (ts_sync)
            global_counter_stage1 <= {TS_WIDTH{1'b0}};
        else
            global_counter_stage1 <= global_counter_stage1 + 1'b1;
    end
end

// Stage 2: 计数器流水线寄存器，信号同步
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        global_counter_stage2 <= {TS_WIDTH{1'b0}};
        ts_sync_stage2        <= 1'b0;
        rx_start_stage2       <= 1'b0;
        tx_start_stage2       <= 1'b0;
        rx_valid_stage2       <= 1'b0;
        tx_valid_stage2       <= 1'b0;
    end else begin
        global_counter_stage2 <= global_counter_stage1;
        ts_sync_stage2        <= ts_sync_stage1;
        rx_start_stage2       <= rx_start_stage1;
        tx_start_stage2       <= tx_start_stage1;
        rx_valid_stage2       <= rx_valid_stage1;
        tx_valid_stage2       <= tx_valid_stage1;
    end
end

// Stage 3: 时间戳捕获
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_timestamp_stage3 <= {TS_WIDTH{1'b0}};
        tx_timestamp_stage3 <= {TS_WIDTH{1'b0}};
        rx_valid_stage3     <= 1'b0;
        tx_valid_stage3     <= 1'b0;
    end else begin
        rx_valid_stage3 <= rx_valid_stage2;
        tx_valid_stage3 <= tx_valid_stage2;
        if (rx_start_stage2)
            rx_timestamp_stage3 <= global_counter_stage2;
        if (tx_start_stage2)
            tx_timestamp_stage3 <= global_counter_stage2;
        if (flush_pipeline) begin
            rx_timestamp_stage3 <= {TS_WIDTH{1'b0}};
            tx_timestamp_stage3 <= {TS_WIDTH{1'b0}};
            rx_valid_stage3     <= 1'b0;
            tx_valid_stage3     <= 1'b0;
        end
    end
end

// 输出寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_timestamp <= {TS_WIDTH{1'b0}};
        tx_timestamp <= {TS_WIDTH{1'b0}};
    end else begin
        if (rx_valid_stage3)
            rx_timestamp <= rx_timestamp_stage3;
        if (tx_valid_stage3)
            tx_timestamp <= tx_timestamp_stage3;
        if (flush_pipeline) begin
            rx_timestamp <= {TS_WIDTH{1'b0}};
            tx_timestamp <= {TS_WIDTH{1'b0}};
        end
    end
end

endmodule