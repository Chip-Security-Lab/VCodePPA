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

//------------------- 信号定义 -------------------
reg        clk_enable_stage1, clk_enable_stage2;
wire       gated_clk;
reg [15:0] wakeup_counter_stage1, wakeup_counter_stage2;
reg        rxd_sync_stage1, rxd_sync_stage2;
reg        rxd_prev_stage1, rxd_prev_stage2;
reg        rxd_activity_stage1, rxd_activity_stage2;
reg        rxd_edge_stage1, rxd_edge_stage2;
reg        wakeup_int_stage1, wakeup_int_stage2;

//------------------- 时钟门控 -------------------
assign gated_clk = clk & clk_enable_stage2;

//------------------- RXD同步流水线 -------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_sync_stage1 <= 1'b1;
        rxd_sync_stage2 <= 1'b1;
    end else begin
        rxd_sync_stage1 <= rxd;
        rxd_sync_stage2 <= rxd_sync_stage1;
    end
end

//------------------- RXD上升沿同步流水线 -------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_prev_stage1 <= 1'b1;
        rxd_prev_stage2 <= 1'b1;
    end else begin
        rxd_prev_stage1 <= rxd_sync_stage1;
        rxd_prev_stage2 <= rxd_prev_stage1;
    end
end

//------------------- RXD边沿检测流水线 -------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_edge_stage1 <= 1'b0;
        rxd_edge_stage2 <= 1'b0;
    end else begin
        rxd_edge_stage1 <= (rxd_sync_stage1 != rxd_prev_stage1);
        rxd_edge_stage2 <= rxd_edge_stage1;
    end
end

//------------------- 时钟门控逻辑流水线 -------------------
always @(negedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_enable_stage1 <= 1'b1;
        clk_enable_stage2 <= 1'b1;
    end else if (clk_gate_en) begin
        clk_enable_stage1 <= ~sleep_en | rxd_activity_stage2;
        clk_enable_stage2 <= clk_enable_stage1;
    end
end

//------------------- RXD活动检测流水线 -------------------
always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_activity_stage1 <= 1'b0;
        rxd_activity_stage2 <= 1'b0;
    end else begin
        // Stage 1: 计算活动
        if (rxd_edge_stage2) begin
            rxd_activity_stage1 <= 1'b1;
        end else if (wakeup_counter_stage2 == 0) begin
            rxd_activity_stage1 <= 1'b0;
        end else begin
            rxd_activity_stage1 <= rxd_activity_stage1;
        end
        // Stage 2: 延迟
        rxd_activity_stage2 <= rxd_activity_stage1;
    end
end

//------------------- 唤醒计数器流水线 -------------------
always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n) begin
        wakeup_counter_stage1 <= 16'd0;
        wakeup_counter_stage2 <= 16'd0;
    end else begin
        // Stage 1: 计数逻辑
        if (rxd_edge_stage2) begin
            wakeup_counter_stage1 <= WAKEUP_TIMEOUT;
        end else if (wakeup_counter_stage2 != 0) begin
            wakeup_counter_stage1 <= wakeup_counter_stage2 - 1'b1;
        end else begin
            wakeup_counter_stage1 <= wakeup_counter_stage2;
        end
        // Stage 2: 延迟
        wakeup_counter_stage2 <= wakeup_counter_stage1;
    end
end

//------------------- 唤醒中断控制流水线 -------------------
always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n) begin
        wakeup_int_stage1 <= 1'b0;
        wakeup_int_stage2 <= 1'b0;
    end else begin
        // Stage 1: 中断逻辑
        if (rxd_edge_stage2) begin
            wakeup_int_stage1 <= 1'b0;
        end else if (wakeup_counter_stage2 == 16'd1) begin
            wakeup_int_stage1 <= 1'b1;
        end else if (wakeup_counter_stage2 == 16'd0) begin
            wakeup_int_stage1 <= 1'b0;
        end else begin
            wakeup_int_stage1 <= wakeup_int_stage1;
        end
        // Stage 2: 延迟
        wakeup_int_stage2 <= wakeup_int_stage1;
    end
end

//------------------- 输出同步 -------------------
always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n) begin
        wakeup_int <= 1'b0;
    end else begin
        wakeup_int <= wakeup_int_stage2;
    end
end

endmodule