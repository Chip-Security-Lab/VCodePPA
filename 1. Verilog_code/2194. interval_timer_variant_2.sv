//SystemVerilog
// 顶层模块
module interval_timer (
    input  wire       clk,
    input  wire       rst,
    input  wire       program_en,
    input  wire [7:0] interval_data,
    input  wire [3:0] interval_sel,
    output wire       event_trigger
);
    // 内部连线
    wire [7:0] interval_value;
    wire       interval_match;
    wire [3:0] next_interval;
    wire [7:0] counter_value;
    
    // 间隔存储模块实例
    interval_storage u_interval_storage (
        .clk           (clk),
        .program_en    (program_en),
        .interval_data (interval_data),
        .interval_sel  (interval_sel),
        .active_sel    (next_interval),
        .interval_out  (interval_value)
    );
    
    // 计数器模块实例
    counter_module u_counter (
        .clk          (clk),
        .rst          (rst),
        .program_en   (program_en),
        .interval     (interval_value),
        .count_value  (counter_value),
        .interval_match (interval_match)
    );
    
    // 事件触发模块实例
    event_generator u_event_gen (
        .clk           (clk),
        .rst           (rst),
        .program_en    (program_en),
        .interval_match (interval_match),
        .event_trigger (event_trigger)
    );
    
    // 间隔选择模块实例
    interval_selector u_interval_sel (
        .clk           (clk),
        .rst           (rst),
        .program_en    (program_en),
        .interval_match (interval_match),
        .next_interval (next_interval)
    );
    
endmodule

// 间隔存储模块
module interval_storage (
    input  wire       clk,
    input  wire       program_en,
    input  wire [7:0] interval_data,
    input  wire [3:0] interval_sel,
    input  wire [3:0] active_sel,
    output reg  [7:0] interval_out
);
    // 参数化存储器深度
    parameter INTERVALS_DEPTH = 16;
    
    // 存储所有间隔的寄存器数组
    reg [7:0] intervals [0:INTERVALS_DEPTH-1];
    
    // 处理interval编程
    always @(posedge clk) begin
        if (program_en) begin
            intervals[interval_sel] <= interval_data;
        end
    end
    
    // 输出当前活动间隔的值
    always @(*) begin
        interval_out = intervals[active_sel];
    end
    
endmodule

// 计数器模块
module counter_module (
    input  wire       clk,
    input  wire       rst,
    input  wire       program_en,
    input  wire [7:0] interval,
    output reg  [7:0] count_value,
    output wire       interval_match
);
    // 处理计数器更新
    always @(posedge clk) begin
        if (rst) begin
            count_value <= 8'd0;
        end else if (!program_en) begin
            if (count_value >= interval) begin
                count_value <= 8'd0;
            end else begin
                count_value <= count_value + 1'b1;
            end
        end
    end
    
    // 生成间隔匹配信号
    assign interval_match = (count_value >= interval) && !program_en;
    
endmodule

// 事件触发模块
module event_generator (
    input  wire clk,
    input  wire rst,
    input  wire program_en,
    input  wire interval_match,
    output reg  event_trigger
);
    // 处理事件触发信号
    always @(posedge clk) begin
        if (rst) begin
            event_trigger <= 1'b0;
        end else if (!program_en) begin
            event_trigger <= interval_match;
        end
    end
    
endmodule

// 间隔选择模块
module interval_selector (
    input  wire       clk,
    input  wire       rst,
    input  wire       program_en,
    input  wire       interval_match,
    output reg  [3:0] next_interval
);
    // 处理活动间隔选择
    always @(posedge clk) begin
        if (rst) begin
            next_interval <= 4'd0;
        end else if (!program_en && interval_match) begin
            next_interval <= next_interval + 1'b1;
        end
    end
    
endmodule