//SystemVerilog
//IEEE 1364-2005 Verilog
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
// ===================
// 信号定义
// ===================
reg        clk_enable;
wire       gated_clk;
assign     gated_clk = clk & clk_enable;

reg  [15:0] wakeup_counter;
reg        rxd_sync_stage1, rxd_sync_stage2;
reg        rxd_edge_detect;
reg        rxd_activity;
wire       rxd_changed;
reg        wakeup_counter_nonzero;
reg        next_rxd_activity;
reg        next_wakeup_int;
reg  [15:0] next_wakeup_counter;

// ===================
// rxd同步与边沿检测
// ===================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_sync_stage1 <= 1'b1;
        rxd_sync_stage2 <= 1'b1;
    end else begin
        rxd_sync_stage1 <= rxd;
        rxd_sync_stage2 <= rxd_sync_stage1;
    end
end

assign rxd_changed = (rxd_sync_stage1 != rxd_sync_stage2);

// ===================
// 时钟门控逻辑(平衡路径)
// ===================
wire sleep_or_no_activity;
assign sleep_or_no_activity = ~sleep_en | rxd_activity;

always @(negedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_enable <= 1'b1;
    end else if (clk_gate_en) begin
        clk_enable <= sleep_or_no_activity;
    end
end

// ===================
// 唤醒计数器非零检测(提前计算)
// ===================
always @(*) begin
    wakeup_counter_nonzero = (wakeup_counter != 16'd0);
end

// ===================
// 活动检测与唤醒逻辑(重构路径，if-else链变case)
// ===================
always @(*) begin
    // 控制变量优先级: rxd_changed最高，其次wakeup_counter_nonzero
    case ({rxd_changed, wakeup_counter_nonzero})
        2'b10: begin
            // rxd_changed=1, wakeup_counter_nonzero=x
            next_rxd_activity    = 1'b1;
            next_wakeup_counter  = WAKEUP_TIMEOUT;
            next_wakeup_int      = 1'b0;
        end
        2'b01: begin
            // rxd_changed=0, wakeup_counter_nonzero=1
            next_wakeup_counter  = wakeup_counter - 16'd1;
            next_rxd_activity    = rxd_activity;
            next_wakeup_int      = (wakeup_counter == 16'd1) ? 1'b1 : 1'b0;
        end
        2'b00: begin
            // rxd_changed=0, wakeup_counter_nonzero=0
            next_rxd_activity    = 1'b0;
            next_wakeup_counter  = 16'd0;
            next_wakeup_int      = 1'b0;
        end
        default: begin
            // 冗余保护
            next_rxd_activity    = 1'b0;
            next_wakeup_counter  = 16'd0;
            next_wakeup_int      = 1'b0;
        end
    endcase
end

always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_activity   <= 1'b0;
        wakeup_counter <= 16'd0;
        wakeup_int     <= 1'b0;
    end else begin
        rxd_activity   <= next_rxd_activity;
        wakeup_counter <= next_wakeup_counter;
        wakeup_int     <= next_wakeup_int;
    end
end

endmodule