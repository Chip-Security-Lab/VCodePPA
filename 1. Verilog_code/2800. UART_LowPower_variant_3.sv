//SystemVerilog
module UART_LowPower #(
    parameter WAKEUP_TIMEOUT = 16'hFFFF
)(
    input  wire clk,             // 时钟信号
    input  wire rst_n,           // 复位信号
    input  wire rxd,             // 接收数据信号
    input  wire sleep_en,        // 睡眠使能
    output reg  wakeup_int,      // 唤醒中断
    input  wire clk_gate_en      // 时钟门控
);

// ----------- RXD同步/边沿检测三级流水线 -----------

reg rxd_sync_stage1;
reg rxd_sync_stage2;
reg rxd_sync_stage3;
reg rxd_prev_stage1;
reg rxd_prev_stage2;
reg rxd_prev_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rxd_sync_stage1 <= 1'b1;
    else
        rxd_sync_stage1 <= rxd;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rxd_sync_stage2 <= 1'b1;
    else
        rxd_sync_stage2 <= rxd_sync_stage1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rxd_sync_stage3 <= 1'b1;
    else
        rxd_sync_stage3 <= rxd_sync_stage2;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rxd_prev_stage1 <= 1'b1;
    else
        rxd_prev_stage1 <= rxd_sync_stage2;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rxd_prev_stage2 <= 1'b1;
    else
        rxd_prev_stage2 <= rxd_prev_stage1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rxd_prev_stage3 <= 1'b1;
    else
        rxd_prev_stage3 <= rxd_prev_stage2;
end

wire rxd_edge_detect_stage;
assign rxd_edge_detect_stage = (rxd_sync_stage3 != rxd_prev_stage3);

// ----------- 时钟门控逻辑两级流水线 -----------

reg clk_enable_stage1;
reg clk_enable_stage2;

always @(negedge clk or negedge rst_n) begin
    if (!rst_n)
        clk_enable_stage1 <= 1'b1;
    else if (clk_gate_en)
        clk_enable_stage1 <= 1'b1;
end

always @(negedge clk or negedge rst_n) begin
    if (!rst_n)
        clk_enable_stage2 <= 1'b1;
    else if (clk_gate_en)
        clk_enable_stage2 <= ~sleep_en | rxd_activity_stage2;
end

wire gated_clk;
assign gated_clk = clk & clk_enable_stage2;

// ----------- 活动检测逻辑一级流水线 -----------

reg rxd_activity_stage1;

always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n)
        rxd_activity_stage1 <= 1'b0;
    else if (rxd_edge_detect_stage)
        rxd_activity_stage1 <= 1'b1;
    else
        rxd_activity_stage1 <= rxd_activity_stage2;
end

// ----------- 活动检测逻辑二级流水线 -----------

reg rxd_activity_stage2;
reg [15:0] wakeup_counter_stage1;
reg [15:0] wakeup_counter_stage2;
reg [15:0] wakeup_counter_stage3;

always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n)
        rxd_activity_stage2 <= 1'b0;
    else if (rxd_edge_detect_stage)
        rxd_activity_stage2 <= 1'b1;
    else if (wakeup_counter_stage2 == 0)
        rxd_activity_stage2 <= 1'b0;
end

// ----------- 唤醒计数器三级流水线 -----------

always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n)
        wakeup_counter_stage1 <= 16'd0;
    else if (rxd_edge_detect_stage)
        wakeup_counter_stage1 <= WAKEUP_TIMEOUT;
    else if (wakeup_counter_stage1 != 16'd0)
        wakeup_counter_stage1 <= wakeup_counter_stage1 - 1'b1;
    else
        wakeup_counter_stage1 <= 16'd0;
end

always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n)
        wakeup_counter_stage2 <= 16'd0;
    else
        wakeup_counter_stage2 <= wakeup_counter_stage1;
end

always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n)
        wakeup_counter_stage3 <= 16'd0;
    else
        wakeup_counter_stage3 <= wakeup_counter_stage2;
end

// ----------- 唤醒中断两级流水线 -----------

reg wakeup_int_stage1;
reg wakeup_int_stage2;

always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n)
        wakeup_int_stage1 <= 1'b0;
    else if (rxd_edge_detect_stage)
        wakeup_int_stage1 <= 1'b0;
    else if (wakeup_counter_stage3 == 16'd1)
        wakeup_int_stage1 <= 1'b1;
    else if (wakeup_counter_stage3 == 16'd0)
        wakeup_int_stage1 <= 1'b0;
end

always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n)
        wakeup_int_stage2 <= 1'b0;
    else
        wakeup_int_stage2 <= wakeup_int_stage1;
end

// ----------- 输出同步 -----------

always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n)
        wakeup_int <= 1'b0;
    else
        wakeup_int <= wakeup_int_stage2;
end

endmodule