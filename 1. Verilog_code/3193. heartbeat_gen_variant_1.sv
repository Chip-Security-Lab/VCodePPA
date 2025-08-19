//SystemVerilog
module heartbeat_gen #(
    parameter IDLE_CYCLES = 1000,
    parameter PULSE_CYCLES = 50
)(
    input clk,
    input rst,
    output reg heartbeat
);

    // 将计数器操作分为多个流水线级
    reg [31:0] counter_stage1;
    reg [31:0] counter_stage2;
    reg [31:0] counter_stage3;
    
    // 流水线控制信号
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    // 心跳信号流水线寄存器
    reg heartbeat_stage1;
    reg heartbeat_stage2;
    reg heartbeat_stage3;
    
    // 流水线第一级：计数和重置逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            valid_stage1 <= 1'b1;
            
            if (valid_stage1) begin
                if (counter_stage3 < IDLE_CYCLES + PULSE_CYCLES) begin
                    counter_stage1 <= counter_stage3 + 1;
                end else begin
                    counter_stage1 <= 0;
                end
            end
        end
    end
    
    // 流水线第二级：计数器传递和条件计算
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_stage2 <= 0;
            valid_stage2 <= 0;
            heartbeat_stage1 <= 0;
        end else begin
            counter_stage2 <= counter_stage1;
            valid_stage2 <= valid_stage1;
            
            // 将心跳条件计算拆分到这一级
            heartbeat_stage1 <= (counter_stage1 >= IDLE_CYCLES) && 
                               (counter_stage1 < IDLE_CYCLES + PULSE_CYCLES);
        end
    end
    
    // 流水线第三级：最终条件计算和输出传递
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_stage3 <= 0;
            valid_stage3 <= 0;
            heartbeat_stage2 <= 0;
            heartbeat_stage3 <= 0;
        end else begin
            counter_stage3 <= counter_stage2;
            valid_stage3 <= valid_stage2;
            heartbeat_stage2 <= heartbeat_stage1;
            heartbeat_stage3 <= heartbeat_stage2;
        end
    end
    
    // 输出级
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            heartbeat <= 0;
        end else begin
            heartbeat <= heartbeat_stage3;
        end
    end
    
endmodule