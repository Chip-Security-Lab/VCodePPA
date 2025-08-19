//SystemVerilog
module int_ctrl_timestamp #(parameter TS_W=16)(
    input                 clk,
    input                 rst_n,         // 添加复位信号
    input                 int_pulse,
    input                 valid_in,      // 输入有效信号
    output                ready_out,     // 输出就绪信号
    output reg [TS_W-1:0] timestamp,
    output reg            valid_out      // 输出有效信号
);
    // 流水线阶段1 - 计数器更新
    reg [TS_W-1:0] counter_stage1;
    reg            int_pulse_stage1;
    reg            valid_stage1;
    
    // 流水线阶段2 - 中间结果存储
    reg [TS_W-1:0] counter_stage2;
    reg            int_pulse_stage2;
    reg            valid_stage2;
    
    // 流水线阶段3 - 时间戳捕获
    reg [TS_W-1:0] counter_stage3;
    reg            int_pulse_stage3;
    reg            valid_stage3;
    
    // 流水线控制信号
    assign ready_out = 1'b1;  // 本设计始终可接收新数据
    
    // 阶段1 - 计数器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1 <= {TS_W{1'b0}};
            int_pulse_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            counter_stage1 <= counter_stage1 + 1'b1;
            int_pulse_stage1 <= int_pulse;
            valid_stage1 <= valid_in;
        end
    end
    
    // 阶段2 - 中间结果存储
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage2 <= {TS_W{1'b0}};
            int_pulse_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            counter_stage2 <= counter_stage1;
            int_pulse_stage2 <= int_pulse_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 阶段3 - 时间戳捕获
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage3 <= {TS_W{1'b0}};
            int_pulse_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            counter_stage3 <= counter_stage2;
            int_pulse_stage3 <= int_pulse_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出阶段 - 根据脉冲更新时间戳
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timestamp <= {TS_W{1'b0}};
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_stage3;
            if (int_pulse_stage3) begin
                timestamp <= counter_stage3;
            end
        end
    end
endmodule