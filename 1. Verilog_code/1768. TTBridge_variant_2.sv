//SystemVerilog
// 顶层模块
module TTBridge #(
    parameter SCHEDULE = 32'h0000_FFFF
)(
    input clk, rst_n,
    input [31:0] timestamp,
    output trigger
);
    // 内部信号
    wire schedule_match;
    wire [31:0] time_diff;
    wire time_valid;
    
    // 实例化子模块
    TimestampTracker timestamp_tracker (
        .clk(clk),
        .rst_n(rst_n),
        .timestamp(timestamp),
        .trigger_out(trigger),
        .schedule_match(schedule_match),
        .time_diff(time_diff),
        .time_valid(time_valid)
    );
    
    ScheduleChecker #(
        .SCHEDULE(SCHEDULE)
    ) schedule_checker (
        .clk(clk),
        .rst_n(rst_n),
        .timestamp(timestamp),
        .schedule_match(schedule_match)
    );
    
    TimeValidator time_validator (
        .clk(clk),
        .rst_n(rst_n),
        .time_diff(time_diff),
        .time_valid(time_valid)
    );
endmodule

// 时间戳记录子模块
module TimestampTracker (
    input clk, rst_n,
    input [31:0] timestamp,
    output reg [31:0] time_diff,
    output reg trigger_out,
    input schedule_match,
    input time_valid
);
    reg [31:0] last_ts;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_ts <= 32'h0;
            time_diff <= 32'h0;
            trigger_out <= 1'b0;
        end else begin
            time_diff <= timestamp - last_ts;
            
            if (schedule_match && time_valid) begin
                trigger_out <= 1'b1;
                last_ts <= timestamp;
            end else begin
                trigger_out <= 1'b0;
            end
        end
    end
endmodule

// 调度检查子模块
module ScheduleChecker #(
    parameter SCHEDULE = 32'h0000_FFFF
)(
    input clk, rst_n,
    input [31:0] timestamp,
    output reg schedule_match
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            schedule_match <= 1'b0;
        end else begin
            schedule_match <= (timestamp & SCHEDULE) != 0;
        end
    end
endmodule

// 时间验证子模块
module TimeValidator (
    input clk, rst_n,
    input [31:0] time_diff,
    output reg time_valid
);
    localparam MIN_TIME_DIFF = 32'd100;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            time_valid <= 1'b0;
        end else begin
            time_valid <= (time_diff >= MIN_TIME_DIFF);
        end
    end
endmodule