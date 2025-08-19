//SystemVerilog
//===================================================================
// Project: Enhanced Interrupt Control System
// Description: Hierarchical interrupt timestamp module with improved PPA
// Standard: IEEE 1364-2005 Verilog
//===================================================================

//===================================================================
// 顶层模块: 中断控制时间戳管理系统
//===================================================================
module int_ctrl_timestamp #(
    parameter TS_W = 16
)(
    input  wire              clk,
    input  wire              int_pulse,
    output wire [TS_W-1:0]   timestamp
);

    // 内部信号定义
    wire [TS_W-1:0] current_count;
    wire            counter_overflow;
    wire            capture_valid;

    // 时间基准生成模块
    timebase_generator #(
        .COUNTER_WIDTH(TS_W)
    ) timebase_inst (
        .clk              (clk),
        .reset_n          (1'b1),         // 无复位信号
        .enable           (1'b1),         // 始终启用
        .count_value      (current_count),
        .overflow         (counter_overflow)
    );

    // 中断捕获和处理模块
    interrupt_handler #(
        .TS_WIDTH(TS_W)
    ) int_handler_inst (
        .clk              (clk),
        .int_pulse        (int_pulse),
        .current_time     (current_count),
        .timestamp        (timestamp),
        .capture_valid    (capture_valid)
    );

endmodule

//===================================================================
// 时间基准生成模块
//===================================================================
module timebase_generator #(
    parameter COUNTER_WIDTH = 16
)(
    input  wire                     clk,
    input  wire                     reset_n,
    input  wire                     enable,
    output reg  [COUNTER_WIDTH-1:0] count_value,
    output wire                     overflow
);

    // 本地参数
    localparam MAX_COUNT = {COUNTER_WIDTH{1'b1}};
    
    // 溢出信号生成
    assign overflow = (count_value == MAX_COUNT) && enable;
    
    // 计数器实现 - 精简时序路径
    always @(posedge clk) begin
        if (!reset_n) begin
            count_value <= {COUNTER_WIDTH{1'b0}};
        end else if (enable) begin
            count_value <= (count_value == MAX_COUNT) ? {COUNTER_WIDTH{1'b0}} : count_value + 1'b1;
        end
    end

endmodule

//===================================================================
// 中断捕获和处理模块
//===================================================================
module interrupt_handler #(
    parameter TS_WIDTH = 16
)(
    input  wire                   clk,
    input  wire                   int_pulse,
    input  wire [TS_WIDTH-1:0]    current_time,
    output reg  [TS_WIDTH-1:0]    timestamp,
    output reg                    capture_valid
);

    // 内部信号
    reg int_pulse_d1;  // 中断信号延迟寄存器，用于边沿检测
    wire int_edge_detected;
    
    // 中断边沿检测
    always @(posedge clk) begin
        int_pulse_d1 <= int_pulse;
    end
    
    assign int_edge_detected = int_pulse && !int_pulse_d1;
    
    // 时间戳捕获处理
    always @(posedge clk) begin
        if (int_pulse) begin
            timestamp <= current_time;
            capture_valid <= 1'b1;
        end else begin
            capture_valid <= 1'b0;
        end
    end

endmodule