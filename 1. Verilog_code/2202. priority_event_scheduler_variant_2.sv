//SystemVerilog
// 顶层模块
module priority_event_scheduler #(
    parameter EVENTS = 8,
    parameter TIMER_WIDTH = 16
)(
    input  wire                     clk,
    input  wire                     reset,
    input  wire [TIMER_WIDTH-1:0]   event_times [EVENTS-1:0],
    input  wire [EVENTS-1:0]        event_priority,
    output wire [2:0]               next_event_id,
    output wire                     event_ready
);
    // 内部连线
    wire [EVENTS-1:0]       timer_expired;
    wire                    reload_timer;
    
    // 使用event_ready作为重载信号
    assign reload_timer = event_ready;
    
    // 实例化事件计时管理子模块
    event_timer_manager #(
        .EVENTS(EVENTS),
        .TIMER_WIDTH(TIMER_WIDTH)
    ) event_timer_manager_inst (
        .clk            (clk),
        .reset          (reset),
        .event_times    (event_times),
        .reload_timer   (reload_timer),
        .reload_id      (next_event_id),
        .timer_expired  (timer_expired)
    );
    
    // 实例化事件优先级选择器子模块
    event_priority_selector #(
        .EVENTS(EVENTS)
    ) event_priority_selector_inst (
        .clk            (clk),
        .reset          (reset),
        .timer_expired  (timer_expired),
        .event_priority (event_priority),
        .next_event_id  (next_event_id),
        .event_ready    (event_ready)
    );
    
endmodule

// 事件计时管理子模块 - 管理所有事件的计时器
module event_timer_manager #(
    parameter EVENTS = 8,
    parameter TIMER_WIDTH = 16
)(
    input  wire                     clk,
    input  wire                     reset,
    input  wire [TIMER_WIDTH-1:0]   event_times [EVENTS-1:0],
    input  wire                     reload_timer,
    input  wire [2:0]               reload_id,
    output wire [EVENTS-1:0]        timer_expired
);
    // 内部信号
    wire [TIMER_WIDTH-1:0] timer_values [EVENTS-1:0];
    
    // 实例化多个单独的计时器
    genvar i;
    generate
        for (i = 0; i < EVENTS; i = i + 1) begin : timer_instances
            single_event_timer #(
                .TIMER_WIDTH(TIMER_WIDTH)
            ) timer_inst (
                .clk            (clk),
                .reset          (reset),
                .event_time     (event_times[i]),
                .reload_timer   (reload_timer && (i == reload_id)),
                .timer_value    (timer_values[i]),
                .timer_expired  (timer_expired[i])
            );
        end
    endgenerate
    
endmodule

// 单个事件计时器子模块 - 处理单个事件的计时
module single_event_timer #(
    parameter TIMER_WIDTH = 16
)(
    input  wire                     clk,
    input  wire                     reset,
    input  wire [TIMER_WIDTH-1:0]   event_time,
    input  wire                     reload_timer,
    output reg  [TIMER_WIDTH-1:0]   timer_value,
    output reg                      timer_expired
);
    
    always @(posedge clk) begin
        if (reset) begin
            timer_value <= event_time;
            timer_expired <= 1'b0;
        end else begin
            // 重置计时器逻辑
            if (reload_timer) begin
                timer_value <= event_time;
                timer_expired <= 1'b0;
            end
            // 计时器递减逻辑
            else if (timer_value > 0) begin
                timer_value <= timer_value - 1'b1;
                
                // 当计时器即将到期时设置过期标志
                if (timer_value == 1) begin
                    timer_expired <= 1'b1;
                end
            end
        end
    end
    
endmodule

// 事件优先级选择器子模块 - 根据计时器状态和优先级选择下一个事件
module event_priority_selector #(
    parameter EVENTS = 8
)(
    input  wire                 clk,
    input  wire                 reset,
    input  wire [EVENTS-1:0]    timer_expired,
    input  wire [EVENTS-1:0]    event_priority,
    output reg  [2:0]           next_event_id,
    output reg                  event_ready
);
    // 将优先级逻辑和计时器过期状态组合
    wire [EVENTS-1:0] eligible_events;
    assign eligible_events = timer_expired & event_priority;
    
    // 优先级逻辑实现
    always @(posedge clk) begin
        if (reset) begin
            next_event_id <= 3'd0;
            event_ready <= 1'b0;
        end else begin
            event_ready <= 1'b0;
            
            // 优先级选择逻辑
            casez (eligible_events)
                8'b1???????: begin next_event_id <= 3'd7; event_ready <= 1'b1; end
                8'b01??????: begin next_event_id <= 3'd6; event_ready <= 1'b1; end
                8'b001?????: begin next_event_id <= 3'd5; event_ready <= 1'b1; end
                8'b0001????: begin next_event_id <= 3'd4; event_ready <= 1'b1; end
                8'b00001???: begin next_event_id <= 3'd3; event_ready <= 1'b1; end
                8'b000001??: begin next_event_id <= 3'd2; event_ready <= 1'b1; end
                8'b0000001?: begin next_event_id <= 3'd1; event_ready <= 1'b1; end
                8'b00000001: begin next_event_id <= 3'd0; event_ready <= 1'b1; end
                default:     begin next_event_id <= next_event_id; event_ready <= 1'b0; end
            endcase
        end
    end
    
endmodule