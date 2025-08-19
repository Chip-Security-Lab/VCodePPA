//SystemVerilog
module timestamp_capture #(
    parameter TIMESTAMP_WIDTH = 32
)(
    input  wire clk,
    input  wire rst,
    input  wire [3:0] event_triggers,
    output reg  [3:0] event_detected,
    output reg  [TIMESTAMP_WIDTH-1:0] timestamps [0:3]
);
    // 主时间戳计数器
    reg [TIMESTAMP_WIDTH-1:0] counter_stage1;
    
    // 边沿检测路径
    reg [3:0] event_triggers_stage1;
    reg [3:0] event_triggers_stage2;
    wire [3:0] rising_edges;
    
    // 流水线控制信号
    reg [3:0] valid_timestamp;

    // =========== 第一级流水线：触发器采样和计数器更新 ===========
    always @(posedge clk) begin
        if (rst) begin
            counter_stage1 <= {TIMESTAMP_WIDTH{1'b0}};
            event_triggers_stage1 <= 4'b0000;
            event_triggers_stage2 <= 4'b0000;
        end else begin
            // 时间戳计数器更新
            counter_stage1 <= counter_stage1 + 1'b1;
            
            // 对输入触发器采样
            event_triggers_stage1 <= event_triggers;
            event_triggers_stage2 <= event_triggers_stage1;
        end
    end

    // =========== 边沿检测逻辑 ===========
    // 将边沿检测拆分为独立的组合逻辑，减少主状态机复杂度
    assign rising_edges = event_triggers_stage1 & ~event_triggers_stage2;

    // =========== 第二级流水线：时间戳捕获控制 ===========
    always @(posedge clk) begin
        if (rst) begin
            valid_timestamp <= 4'b0000;
        end else begin
            valid_timestamp <= rising_edges;
        end
    end

    // =========== 第三级流水线：时间戳捕获和输出 ===========
    // 将时间戳捕获与边沿检测分开，形成清晰的数据通路
    always @(posedge clk) begin
        if (rst) begin
            event_detected <= 4'b0000;
            // 重置时间戳初始值
            timestamps[0] <= {TIMESTAMP_WIDTH{1'b0}};
            timestamps[1] <= {TIMESTAMP_WIDTH{1'b0}};
            timestamps[2] <= {TIMESTAMP_WIDTH{1'b0}};
            timestamps[3] <= {TIMESTAMP_WIDTH{1'b0}};
        end else begin
            // 使用独立的通道控制信号更新时间戳
            if (valid_timestamp[0]) begin
                timestamps[0] <= counter_stage1;
                event_detected[0] <= 1'b1;
            end
            
            if (valid_timestamp[1]) begin
                timestamps[1] <= counter_stage1;
                event_detected[1] <= 1'b1;
            end
            
            if (valid_timestamp[2]) begin
                timestamps[2] <= counter_stage1;
                event_detected[2] <= 1'b1;
            end
            
            if (valid_timestamp[3]) begin
                timestamps[3] <= counter_stage1;
                event_detected[3] <= 1'b1;
            end
        end
    end
endmodule