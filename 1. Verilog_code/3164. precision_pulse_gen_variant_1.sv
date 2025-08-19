//SystemVerilog
module precision_pulse_gen #(
    parameter CLK_FREQ_HZ = 100000000,
    parameter PULSE_US = 10
)(
    input clk,
    input rst_n,
    input trigger,
    output reg pulse_out,
    input ready_in,
    output reg valid_out
);
    localparam COUNT = (CLK_FREQ_HZ / 1000000) * PULSE_US;
    localparam COUNT_WIDTH = $clog2(COUNT);
    
    // 流水线阶段1 - 触发检测和初始化
    reg trigger_stage1, active_stage1;
    reg [COUNT_WIDTH-1:0] counter_stage1;
    reg valid_stage1;
    
    // 流水线阶段2 - 计数处理
    reg active_stage2;
    reg [COUNT_WIDTH-1:0] counter_stage2;
    reg pulse_stage2;
    reg valid_stage2;
    
    // 流水线阶段3 - 输出生成
    reg active_stage3;
    reg pulse_stage3;
    
    // 第一级流水线 - 触发检测
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {trigger_stage1, active_stage1, valid_stage1} <= 3'b0;
            counter_stage1 <= {COUNT_WIDTH{1'b0}};
        end else if (ready_in) begin
            trigger_stage1 <= trigger;
            if (trigger && !active_stage3) begin
                {active_stage1, valid_stage1} <= 2'b11;
                counter_stage1 <= {COUNT_WIDTH{1'b0}};
            end else if (active_stage3) begin
                active_stage1 <= (counter_stage2 != COUNT-2);
                counter_stage1 <= counter_stage2 + 1'b1;
                valid_stage1 <= 1'b1;
            end else begin
                {active_stage1, valid_stage1} <= 2'b00;
                counter_stage1 <= {COUNT_WIDTH{1'b0}};
            end
        end
    end
    
    // 第二级流水线 - 计数逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {active_stage2, pulse_stage2, valid_stage2} <= 3'b0;
            counter_stage2 <= {COUNT_WIDTH{1'b0}};
        end else begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                active_stage2 <= active_stage1;
                counter_stage2 <= counter_stage1;
                pulse_stage2 <= (trigger_stage1 && !active_stage3) ? 1'b1 :
                               (active_stage1 && counter_stage1 == COUNT-2) ? 1'b0 :
                               pulse_out;
            end
        end
    end
    
    // 第三级流水线 - 输出生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {active_stage3, pulse_out, valid_out, pulse_stage3} <= 4'b0;
        end else begin
            valid_out <= valid_stage2;
            if (valid_stage2) begin
                active_stage3 <= active_stage2;
                pulse_out <= pulse_stage2;
                pulse_stage3 <= pulse_stage2;
            end
        end
    end
endmodule