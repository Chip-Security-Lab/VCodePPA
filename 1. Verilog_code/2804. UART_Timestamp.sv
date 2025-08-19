module UART_Timestamp #(
    parameter TS_WIDTH = 32,
    parameter TS_CLK_HZ = 100_000_000
)(
    input wire clk,         // 添加时钟输入
    input wire rx_start,    // 添加接收开始信号
    input wire tx_start,    // 添加发送开始信号
    output reg [TS_WIDTH-1:0] rx_timestamp,
    output reg [TS_WIDTH-1:0] tx_timestamp,
    input wire ts_sync      // 时间同步脉冲
);
// 高精度时间计数器
reg [TS_WIDTH-1:0] global_counter;

always @(posedge clk) begin
    if (ts_sync)
        global_counter <= 0;
    else
        global_counter <= global_counter + 1;
end

// 时间标记捕获
always @(posedge clk) begin
    if (rx_start)
        rx_timestamp <= global_counter;
    if (tx_start)
        tx_timestamp <= global_counter;
end

// 移除了real类型函数，改为参数
// 使用整数转换而不是$itor
parameter TS_CLK_DIVIDEND = 1_000_000;  // 百万分之一秒精度
parameter TS_CLK_DIVISOR = TS_CLK_HZ / TS_CLK_DIVIDEND;
endmodule