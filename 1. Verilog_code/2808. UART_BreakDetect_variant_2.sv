//SystemVerilog
module UART_BreakDetect #(
    parameter BREAK_MIN = 16  // 最小Break时钟数
)(
    input wire clk,
    input wire rxd,
    output wire break_event,
    output wire [15:0] break_duration
);

// Stage 1: RXD输入同步与消抖
reg [2:0] rxd_filter_stage1;
always @(posedge clk) begin
    rxd_filter_stage1 <= {rxd_filter_stage1[1:0], rxd};
end

wire rxd_filtered_stage1;
assign rxd_filtered_stage1 = rxd_filter_stage1[2];

// Stage 2: 低电平检测与持续时间计数准备
reg rxd_filtered_stage2;
reg [2:0] rxd_filter_stage2;
always @(posedge clk) begin
    rxd_filtered_stage2 <= rxd_filtered_stage1;
    rxd_filter_stage2 <= rxd_filter_stage1;
end

// Stage 3: 低电平计数逻辑分离
reg [15:0] low_counter_stage3;
reg [15:0] low_counter_next_stage3;
always @(*) begin
    if (rxd_filtered_stage2 == 1'b0) begin
        low_counter_next_stage3 = low_counter_stage3 + 1'b1;
    end else begin
        low_counter_next_stage3 = 16'd0;
    end
end
always @(posedge clk) begin
    low_counter_stage3 <= low_counter_next_stage3;
end

// Stage 4: break事件检测准备
reg [15:0] low_counter_stage4;
reg rxd_filtered_stage4;
always @(posedge clk) begin
    low_counter_stage4 <= low_counter_stage3;
    rxd_filtered_stage4 <= rxd_filtered_stage2;
end

// Stage 5: break_event使能检测与输出锁存
reg break_event_stage5;
reg [15:0] break_duration_stage5;
wire break_event_enable_stage5;
assign break_event_enable_stage5 = (rxd_filtered_stage4 == 1'b1) && (low_counter_stage4 > BREAK_MIN);

reg [2:0] rxd_filter_stage5;
always @(posedge clk) begin
    rxd_filter_stage5 <= rxd_filter_stage2;
    if (break_event_enable_stage5) begin
        break_event_stage5 <= 1'b1;
        break_duration_stage5 <= low_counter_stage4;
    end else if (rxd_filter_stage5[2] & rxd_filter_stage5[1]) begin
        break_event_stage5 <= 1'b0;
    end
end

assign break_event = break_event_stage5;
assign break_duration = break_duration_stage5;

endmodule