//SystemVerilog
module UART_BreakDetect #(
    parameter BREAK_MIN = 16  // 最小Break时钟数
)(
    input  wire        clk,
    input  wire        rst_n,        // 新增异步复位，确保流水线寄存器初始化
    input  wire        rxd,
    output wire        break_event,
    output wire [15:0] break_duration,
    output wire        break_valid   // 新增输出，表示break_event有效
);

// -------------------------------------------------------------
// Stage 1: 输入采样与消抖
// -------------------------------------------------------------
reg [2:0] rxd_filter_stage1;
reg       rxd_sample_stage1;
reg       valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_filter_stage1  <= 3'b111;
        rxd_sample_stage1  <= 1'b1;
        valid_stage1       <= 1'b0;
    end else begin
        rxd_filter_stage1  <= {rxd_filter_stage1[1:0], rxd};
        rxd_sample_stage1  <= rxd_filter_stage1[2] & rxd_filter_stage1[1] & rxd_filter_stage1[0]; // 多位消抖
        valid_stage1       <= 1'b1;
    end
end

// -------------------------------------------------------------
// Stage 2: Break低电平计数
// -------------------------------------------------------------
reg [15:0] low_counter_stage2;
reg        rxd_last_stage2;
reg        valid_stage2;
reg [15:0] low_counter_latch_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        low_counter_stage2      <= 16'd0;
        rxd_last_stage2         <= 1'b1;
        valid_stage2            <= 1'b0;
        low_counter_latch_stage2<= 16'd0;
    end else begin
        rxd_last_stage2 <= rxd_sample_stage1;
        valid_stage2    <= valid_stage1;

        if (rxd_sample_stage1 == 1'b0) begin
            low_counter_stage2 <= low_counter_stage2 + 1'b1;
        end else begin
            low_counter_latch_stage2 <= low_counter_stage2;
            low_counter_stage2 <= 16'd0;
        end
    end
end

// -------------------------------------------------------------
// Stage 3: Break事件检测与输出寄存
// -------------------------------------------------------------
reg        break_event_stage3;
reg [15:0] break_duration_stage3;
reg        valid_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        break_event_stage3    <= 1'b0;
        break_duration_stage3 <= 16'd0;
        valid_stage3          <= 1'b0;
    end else begin
        valid_stage3 <= valid_stage2;

        if ( (rxd_last_stage2 == 1'b0) && (rxd_sample_stage1 == 1'b1) && (low_counter_latch_stage2 > BREAK_MIN) ) begin
            break_event_stage3    <= 1'b1;
            break_duration_stage3 <= low_counter_latch_stage2;
        end else begin
            break_event_stage3    <= 1'b0;
            break_duration_stage3 <= break_duration_stage3;
        end
    end
end

// -------------------------------------------------------------
// 输出赋值
// -------------------------------------------------------------
assign break_event     = break_event_stage3;
assign break_duration  = break_duration_stage3;
assign break_valid     = valid_stage3;

endmodule