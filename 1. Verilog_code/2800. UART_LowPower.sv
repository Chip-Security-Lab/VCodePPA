module UART_LowPower #(
    parameter WAKEUP_TIMEOUT = 16'hFFFF
)(
    input  wire clk,          // 添加时钟信号
    input  wire rst_n,        // 添加复位信号
    input  wire rxd,          // 添加接收数据信号
    input  wire sleep_en,     // 睡眠使能
    output reg  wakeup_int,   // 唤醒中断
    input  wire clk_gate_en   // 时钟门控
);
// 电源管理单元
reg  clk_enable;
wire gated_clk;
assign gated_clk = clk & clk_enable;

// 唤醒检测器
reg [15:0] wakeup_counter;
reg rxd_sync;
reg rxd_activity;
reg rxd_prev;

// 活动检测 - 边沿检测
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_prev <= 1'b1;
        rxd_sync <= 1'b1;
    end else begin
        rxd_prev <= rxd_sync;
        rxd_sync <= rxd;
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

// 活动检测逻辑
always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_activity <= 0;
        wakeup_counter <= 0;
        wakeup_int <= 0;
    end else begin
        if (rxd_sync != rxd_prev) begin
            rxd_activity <= 1'b1;
            wakeup_counter <= WAKEUP_TIMEOUT;
            wakeup_int <= 0;
        end else if (wakeup_counter != 0) begin
            wakeup_counter <= wakeup_counter - 1;
            if (wakeup_counter == 1) begin
                wakeup_int <= 1'b1;
            end
        end else begin
            rxd_activity <= 1'b0;
            wakeup_int <= 0;
        end
    end
end
endmodule