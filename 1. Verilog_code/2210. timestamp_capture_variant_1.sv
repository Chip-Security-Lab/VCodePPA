//SystemVerilog
module timestamp_capture #(
    parameter TIMESTAMP_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire [3:0] event_triggers,
    output reg [3:0] event_detected,
    output reg [TIMESTAMP_WIDTH-1:0] timestamps [0:3]
);
    reg [TIMESTAMP_WIDTH-1:0] free_running_counter;
    reg [3:0] last_triggers;
    
    // 优化的边沿检测信号
    wire [3:0] rising_edges;
    
    // 计算所有通道的上升沿
    assign rising_edges = event_triggers & ~last_triggers;
    
    always @(posedge clk) begin
        if (rst) begin
            free_running_counter <= {TIMESTAMP_WIDTH{1'b0}};
            event_detected <= 4'b0000;
            last_triggers <= 4'b0000;
            
            // 重置时间戳寄存器
            timestamps[0] <= {TIMESTAMP_WIDTH{1'b0}};
            timestamps[1] <= {TIMESTAMP_WIDTH{1'b0}};
            timestamps[2] <= {TIMESTAMP_WIDTH{1'b0}};
            timestamps[3] <= {TIMESTAMP_WIDTH{1'b0}};
        end else begin
            // 更新自由运行计数器
            free_running_counter <= free_running_counter + 1'b1;
            
            // 更新上一个触发状态
            last_triggers <= event_triggers;
            
            // 使用并行结构替代串行比较，减少关键路径
            // 并移除不必要的寄存器索引计算
            if (rising_edges[0]) begin
                timestamps[0] <= free_running_counter;
                event_detected[0] <= 1'b1;
            end
            
            if (rising_edges[1]) begin
                timestamps[1] <= free_running_counter;
                event_detected[1] <= 1'b1;
            end
            
            if (rising_edges[2]) begin
                timestamps[2] <= free_running_counter;
                event_detected[2] <= 1'b1;
            end
            
            if (rising_edges[3]) begin
                timestamps[3] <= free_running_counter;
                event_detected[3] <= 1'b1;
            end
        end
    end
endmodule