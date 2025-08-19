//SystemVerilog
module int_ctrl_timestamp #(
    parameter TS_W = 16
)(
    input wire clk,          // 时钟信号
    input wire rst_n,        // 复位信号，低电平有效
    input wire int_pulse,    // 中断脉冲
    input wire valid_in,     // 输入有效信号 
    output wire valid_out,   // 输出有效信号
    output reg [TS_W-1:0] timestamp // 时间戳输出
);

    // 计数器逻辑
    reg [TS_W-1:0] counter;
    
    // 直接捕获输入信号，无需先寄存
    wire valid_direct = valid_in;
    wire int_pulse_direct = int_pulse;
    
    // 阶段1: 前向寄存后的输入信号和捕获计数器
    reg valid_stage1;
    reg int_pulse_stage1;
    reg [TS_W-1:0] counter_captured_stage1;
    
    // 阶段2: 时间戳更新逻辑
    reg valid_stage2;
    reg int_pulse_stage2;
    reg [TS_W-1:0] counter_captured_stage2;
    
    // 计数器递增逻辑 - 保持独立
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {TS_W{1'b0}};
        end else begin
            counter <= counter + 1'b1;
        end
    end
    
    // 阶段1: 前向寄存 - 直接处理输入信号
    // 实施前向重定时优化：不立即寄存输入，而是直接传递至组合逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            int_pulse_stage1 <= 1'b0;
            counter_captured_stage1 <= {TS_W{1'b0}};
        end else begin
            // 直接从输入到第一级寄存
            valid_stage1 <= valid_direct;
            int_pulse_stage1 <= int_pulse_direct;
            
            // 关键优化：在第一个时钟周期直接捕获计数器值
            // 减少输入到第一级寄存之间的延迟
            counter_captured_stage1 <= counter;
        end
    end
    
    // 阶段2: 将捕获的值传递到下一级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            int_pulse_stage2 <= 1'b0;
            counter_captured_stage2 <= {TS_W{1'b0}};
        end else begin
            valid_stage2 <= valid_stage1;
            int_pulse_stage2 <= int_pulse_stage1;
            counter_captured_stage2 <= counter_captured_stage1;
        end
    end
    
    // 最终阶段: 时间戳更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timestamp <= {TS_W{1'b0}};
        end else if (valid_stage2 && int_pulse_stage2) begin
            timestamp <= counter_captured_stage2;
        end
    end
    
    // 输出有效信号
    assign valid_out = valid_stage2;

endmodule