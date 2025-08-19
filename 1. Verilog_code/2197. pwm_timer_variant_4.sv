//SystemVerilog
module pwm_timer #(
    parameter COUNTER_WIDTH = 12
)(
    input wire clk_i,
    input wire rst_n_i,
    input wire [COUNTER_WIDTH-1:0] period_i,
    input wire [COUNTER_WIDTH-1:0] duty_i,
    output reg pwm_o
);
    // 流水线阶段 1 信号 - 计数器更新
    reg [COUNTER_WIDTH-1:0] counter_stage1;
    reg counter_reset_stage1;
    
    // 流水线阶段 2 信号 - 比较计算
    reg [COUNTER_WIDTH-1:0] counter_stage2;
    reg [COUNTER_WIDTH-1:0] duty_stage2;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    
    // 阶段 1: 计数器逻辑
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            counter_stage1 <= {COUNTER_WIDTH{1'b0}};
            counter_reset_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
            
            if (counter_stage1 >= period_i - 1) begin
                counter_stage1 <= {COUNTER_WIDTH{1'b0}};
                counter_reset_stage1 <= 1'b1;
            end else begin
                counter_stage1 <= counter_stage1 + 1'b1;
                counter_reset_stage1 <= 1'b0;
            end
        end
    end
    
    // 阶段 2: 传递计数器值和占空比到比较阶段
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            counter_stage2 <= {COUNTER_WIDTH{1'b0}};
            duty_stage2 <= {COUNTER_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            counter_stage2 <= counter_stage1;
            duty_stage2 <= duty_i;  // 捕获当前的占空比值
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出阶段: 比较并生成PWM输出
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            pwm_o <= 1'b0;
        end else if (valid_stage2) begin
            pwm_o <= (counter_stage2 < duty_stage2) ? 1'b1 : 1'b0;
        end
    end
endmodule