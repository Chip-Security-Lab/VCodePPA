//SystemVerilog
module UART_LowPower #(
    parameter WAKEUP_TIMEOUT = 16'hFFFF
)(
    input  wire clk,              // 时钟信号
    input  wire rst_n,            // 复位信号
    input  wire rxd,              // 接收数据信号
    input  wire sleep_en,         // 睡眠使能
    output reg  wakeup_int,       // 唤醒中断
    input  wire clk_gate_en       // 时钟门控
);

// 时钟门控相关信号
reg  clk_enable;
wire gated_clk;
assign gated_clk = clk & clk_enable;

// RXD同步相关信号
reg rxd_sync;
reg rxd_prev;

// 活动检测相关信号
reg rxd_activity;

// 唤醒计数器
reg [15:0] wakeup_counter;

// RXD输入同步
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_sync <= 1'b1;
    end else begin
        rxd_sync <= rxd;
    end
end

// RXD上一个值保存
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_prev <= 1'b1;
    end else begin
        rxd_prev <= rxd_sync;
    end
end

// 时钟门控逻辑
always @(negedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_enable <= 1'b1;
    end else if (clk_gate_en) begin
        clk_enable <= ~sleep_en | rxd_activity;
    end
end

// RXD变化检测，产生rxd_activity脉冲
reg rxd_edge_detected;
always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_edge_detected <= 1'b0;
    end else begin
        rxd_edge_detected <= (rxd_sync != rxd_prev);
    end
end

// rxd_activity控制逻辑
always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_activity <= 1'b0;
    end else if (rxd_edge_detected) begin
        rxd_activity <= 1'b1;
    end else if (wakeup_counter == 0) begin
        rxd_activity <= 1'b0;
    end
end

// 唤醒计数器逻辑
always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n) begin
        wakeup_counter <= 16'd0;
    end else if (rxd_edge_detected) begin
        wakeup_counter <= WAKEUP_TIMEOUT;
    end else if (wakeup_counter != 0) begin
        wakeup_counter <= wakeup_counter - 1'b1;
    end
end

// 唤醒中断逻辑
always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n) begin
        wakeup_int <= 1'b0;
    end else if (rxd_edge_detected) begin
        wakeup_int <= 1'b0;
    end else if (wakeup_counter == 16'd1) begin
        wakeup_int <= 1'b1;
    end else if (wakeup_counter == 16'd0) begin
        wakeup_int <= 1'b0;
    end
end

endmodule