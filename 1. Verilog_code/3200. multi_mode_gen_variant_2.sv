//SystemVerilog
module multi_mode_gen #(
    parameter MODE_WIDTH = 2
)(
    input clk,
    input rst_n,
    input [MODE_WIDTH-1:0] mode,
    input [15:0] param,
    output reg signal_out,
    output reg valid_out
);
    // 流水线寄存器
    reg [15:0] counter;
    reg [15:0] counter_stage1;
    reg [MODE_WIDTH-1:0] mode_stage1;
    reg [15:0] param_stage1;
    reg valid_stage1;
    
    // 流水线阶段2需要的中间信号
    reg pwm_result_stage1;
    reg pulse_result_stage1;
    reg div_result_stage1;
    reg rand_result_stage1;
    
    // 阶段1: 计数器更新和初始计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 16'd0;
            counter_stage1 <= 16'd0;
            mode_stage1 <= {MODE_WIDTH{1'b0}};
            param_stage1 <= 16'd0;
            valid_stage1 <= 1'b0;
        end else begin
            // 更新计数器
            counter <= counter + 1'b1;
            
            // 寄存必要输入到阶段1
            counter_stage1 <= counter;
            mode_stage1 <= mode;
            param_stage1 <= param;
            valid_stage1 <= 1'b1; // 数据有效
        end
    end
    
    // 阶段2: 各模式的逻辑计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_result_stage1 <= 1'b0;
            pulse_result_stage1 <= 1'b0;
            div_result_stage1 <= 1'b0;
            rand_result_stage1 <= 1'b0;
        end else if (valid_stage1) begin
            // 并行计算各种模式的结果
            pwm_result_stage1 <= (counter_stage1 < param_stage1);        // PWM模式
            pulse_result_stage1 <= (counter_stage1 == 16'd0);            // 单脉冲模式
            div_result_stage1 <= counter_stage1[param_stage1[3:0]];      // 分频模式
            rand_result_stage1 <= ^counter_stage1[15:8];                 // 随机模式
        end
    end
    
    // 阶段3: 选择和输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_stage1;
            
            // 选择输出信号
            case(mode_stage1)
                2'b00: signal_out <= pwm_result_stage1;    // PWM模式
                2'b01: signal_out <= pulse_result_stage1;  // 单脉冲模式
                2'b10: signal_out <= div_result_stage1;    // 分频模式
                2'b11: signal_out <= rand_result_stage1;   // 随机模式
            endcase
        end
    end
endmodule