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
    
    // 缓冲寄存器，用于减轻高扇出信号的负载
    reg [3:0] event_triggers_buf1, event_triggers_buf2;
    reg [3:0] last_triggers_buf1, last_triggers_buf2;
    reg [TIMESTAMP_WIDTH-1:0] free_running_counter_buf1;
    reg [TIMESTAMP_WIDTH-1:0] free_running_counter_buf2;
    
    // 自由运行计数器模块
    always @(posedge clk) begin
        if (rst) begin
            free_running_counter <= {TIMESTAMP_WIDTH{1'b0}};
        end else begin
            free_running_counter <= free_running_counter + 1'b1;
        end
    end
    
    // 缓冲free_running_counter的高扇出负载
    always @(posedge clk) begin
        if (rst) begin
            free_running_counter_buf1 <= {TIMESTAMP_WIDTH{1'b0}};
            free_running_counter_buf2 <= {TIMESTAMP_WIDTH{1'b0}};
        end else begin
            free_running_counter_buf1 <= free_running_counter;
            free_running_counter_buf2 <= free_running_counter;
        end
    end
    
    // 事件触发器状态记录模块
    always @(posedge clk) begin
        if (rst) begin
            last_triggers <= 4'b0000;
        end else begin
            last_triggers <= event_triggers;
        end
    end
    
    // 缓冲event_triggers和last_triggers的高扇出负载
    always @(posedge clk) begin
        if (rst) begin
            event_triggers_buf1 <= 4'b0000;
            event_triggers_buf2 <= 4'b0000;
            last_triggers_buf1 <= 4'b0000;
            last_triggers_buf2 <= 4'b0000;
        end else begin
            event_triggers_buf1 <= event_triggers;
            event_triggers_buf2 <= event_triggers;
            last_triggers_buf1 <= last_triggers;
            last_triggers_buf2 <= last_triggers;
        end
    end
    
    // 边沿检测和时间戳捕获模块 - 分解为两个并行处理模块以减少关键路径延迟
    always @(posedge clk) begin
        if (rst) begin
            event_detected[1:0] <= 2'b00;
            timestamps[0] <= {TIMESTAMP_WIDTH{1'b0}};
            timestamps[1] <= {TIMESTAMP_WIDTH{1'b0}};
        end else begin
            // Edge detection for channel 0
            if (event_triggers_buf1[0] && !last_triggers_buf1[0]) begin
                timestamps[0] <= free_running_counter_buf1;
                event_detected[0] <= 1'b1;
            end
            
            // Edge detection for channel 1
            if (event_triggers_buf1[1] && !last_triggers_buf1[1]) begin
                timestamps[1] <= free_running_counter_buf1;
                event_detected[1] <= 1'b1;
            end
        end
    end
    
    // 第二部分边沿检测和时间戳捕获模块 - 并行处理另外两个通道
    always @(posedge clk) begin
        if (rst) begin
            event_detected[3:2] <= 2'b00;
            timestamps[2] <= {TIMESTAMP_WIDTH{1'b0}};
            timestamps[3] <= {TIMESTAMP_WIDTH{1'b0}};
        end else begin            
            // Edge detection for channel 2
            if (event_triggers_buf2[2] && !last_triggers_buf2[2]) begin
                timestamps[2] <= free_running_counter_buf2;
                event_detected[2] <= 1'b1;
            end
            
            // Edge detection for channel 3
            if (event_triggers_buf2[3] && !last_triggers_buf2[3]) begin
                timestamps[3] <= free_running_counter_buf2;
                event_detected[3] <= 1'b1;
            end
        end
    end
    
endmodule