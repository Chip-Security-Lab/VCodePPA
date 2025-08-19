//SystemVerilog
module UART_LowPower #(
    parameter WAKEUP_TIMEOUT = 16'hFFFF
)(
    input  wire clk,
    input  wire rst_n,
    input  wire rxd,
    input  wire sleep_en,
    output reg  wakeup_int,
    input  wire clk_gate_en
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

// 活动检测逻辑（优化后的比较链）
always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_activity   <= 1'b0;
        wakeup_counter <= {16{1'b0}};
        wakeup_int     <= 1'b0;
    end else if (rxd_sync != rxd_prev) begin
        rxd_activity   <= 1'b1;
        wakeup_counter <= WAKEUP_TIMEOUT;
        wakeup_int     <= 1'b0;
    end else if (wakeup_counter > 16'd1) begin
        wakeup_counter <= wakeup_counter - 16'd1;
        wakeup_int     <= 1'b0;
    end else if (wakeup_counter == 16'd1) begin
        wakeup_counter <= 16'd0;
        wakeup_int     <= 1'b1;
    end else begin
        rxd_activity   <= 1'b0;
        wakeup_int     <= 1'b0;
    end
end

endmodule