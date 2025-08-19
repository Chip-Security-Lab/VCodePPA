//SystemVerilog
module UART_BreakDetect #(
    parameter BREAK_MIN = 16  // 最小Break时钟数
)(
    input wire clk,                   // 时钟输入
    input wire rxd,                   // 接收数据输入
    output reg break_event,
    output reg [15:0] break_duration
);

    // Stage 1: 输入同步和边沿检测
    reg rxd_sync_stage1, rxd_sync_stage2, rxd_sync_stage3;
    always @(posedge clk) begin
        rxd_sync_stage1 <= rxd;
        rxd_sync_stage2 <= rxd_sync_stage1;
        rxd_sync_stage3 <= rxd_sync_stage2;
    end

    // Stage 2: 低电平计数
    reg [15:0] low_counter_reg;
    reg rxd_last_reg;
    always @(posedge clk) begin
        rxd_last_reg <= rxd_sync_stage3;
        if (rxd_sync_stage3 == 1'b0) begin
            low_counter_reg <= low_counter_reg + 1'b1;
        end else begin
            low_counter_reg <= 16'd0;
        end
    end

    // Stage 3: 判断Break事件条件，寄存器重定时
    wire [15:0] low_counter_stage3;
    wire rxd_last_stage3;
    assign low_counter_stage3 = low_counter_reg;
    assign rxd_last_stage3 = rxd_last_reg;

    wire break_event_comb;
    wire [15:0] break_duration_comb;

    assign break_event_comb = ((rxd_last_stage3 == 1'b0) && (rxd_sync_stage3 == 1'b1) && (low_counter_stage3 > BREAK_MIN)) ? 1'b1 : 1'b0;
    assign break_duration_comb = ((rxd_last_stage3 == 1'b0) && (rxd_sync_stage3 == 1'b1) && (low_counter_stage3 > BREAK_MIN)) ? low_counter_stage3 : 16'd0;

    // Stage 4: 缓存组合逻辑结果（原break_event_stage3/break_duration_stage3移到组合逻辑之前）
    reg break_event_stage4;
    reg [15:0] break_duration_stage4;
    always @(posedge clk) begin
        break_event_stage4 <= break_event_comb;
        break_duration_stage4 <= break_duration_comb;
    end

    // Stage 5: 多级缓冲（原stage4,5合并），保持pipeline深度
    reg break_event_stage5, break_event_stage6;
    reg [15:0] break_duration_stage5, break_duration_stage6;
    always @(posedge clk) begin
        break_event_stage5 <= break_event_stage4;
        break_duration_stage5 <= break_duration_stage4;
        break_event_stage6 <= break_event_stage5;
        break_duration_stage6 <= break_duration_stage5;
    end

    // Stage 6: break_filter多级缓冲（保持原样）
    reg [2:0] break_filter_stage1, break_filter_stage2, break_filter_stage3;
    always @(posedge clk) begin
        break_filter_stage1 <= {break_filter_stage1[1:0], rxd_sync_stage3};
        break_filter_stage2 <= break_filter_stage1;
        break_filter_stage3 <= break_filter_stage2;
    end

    // Stage 7: 输出控制（寄存器移到组合逻辑之前，输出端reg推迟至此）
    always @(posedge clk) begin
        if (break_event_stage6) begin
            break_event <= 1'b1;
            break_duration <= break_duration_stage6;
        end else if (break_filter_stage3[2] & break_filter_stage3[1]) begin
            break_event <= 1'b0;
        end
    end

endmodule