//SystemVerilog
module int_ctrl_timestamp #(
    parameter TS_W = 16
)(
    input wire clk,
    input wire rst_n,      // 添加复位信号
    input wire int_pulse,
    input wire ready_in,   // 输入就绪信号
    output wire ready_out, // 输出就绪信号
    output wire valid_out, // 输出有效信号
    output reg [TS_W-1:0] timestamp
);
    // 流水线阶段定义
    // 阶段1: 检测中断并捕获计数器值
    // 阶段2: 处理时间戳更新

    // 流水线寄存器
    reg [TS_W-1:0] counter;
    reg [TS_W-1:0] counter_stage1;
    reg int_pulse_stage1;
    reg valid_stage1;
    reg valid_stage2;

    // 流水线控制逻辑
    assign ready_out = 1'b1; // 始终准备接收新的中断
    assign valid_out = valid_stage2;

    // 阶段1: 检测中断并捕获计数器值
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= {TS_W{1'b0}};
            counter_stage1 <= {TS_W{1'b0}};
            int_pulse_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else if (ready_in) begin
            // 计数器递增
            counter <= counter + 1'b1;
            
            // 捕获中断和当前计数器值到阶段1
            int_pulse_stage1 <= int_pulse;
            counter_stage1 <= counter;
            
            // 仅当有中断脉冲时设置有效标志
            valid_stage1 <= int_pulse;
        end
    end

    // 阶段2: 处理时间戳更新
    always @(posedge clk) begin
        if (!rst_n) begin
            timestamp <= {TS_W{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else begin
            // 传递有效标志
            valid_stage2 <= valid_stage1;
            
            // 当阶段1产生有效数据时更新时间戳
            if (valid_stage1 && int_pulse_stage1) begin
                timestamp <= counter_stage1;
            end
        end
    end
endmodule