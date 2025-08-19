//SystemVerilog
module var_duty_pwm_clk #(
    parameter PERIOD = 16
)(
    input clk_in,
    input rst,
    input [3:0] duty,  // 0-15 (0%-93.75%)
    output reg clk_out
);
    // 流水线阶段寄存器
    reg [$clog2(PERIOD)-1:0] counter_stage1;
    reg [3:0] duty_stage1, duty_stage2;
    reg [$clog2(PERIOD)-1:0] counter_stage2;
    reg valid_stage1, valid_stage2, valid_stage3;
    reg [3:0] duty_complement_stage2;
    reg [$clog2(PERIOD):0] add_result_stage3;
    reg comparison_result_stage3;
    
    // 第一阶段：计数器更新和输入寄存
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter_stage1 <= 0;
            duty_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            counter_stage1 <= (counter_stage1 < PERIOD-1) ? counter_stage1 + 1'b1 : 0;
            duty_stage1 <= duty;
            valid_stage1 <= 1'b1;
        end
    end
    
    // 第二阶段：计算补码
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            duty_stage2 <= 0;
            counter_stage2 <= 0;
            duty_complement_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            duty_stage2 <= duty_stage1;
            counter_stage2 <= counter_stage1;
            duty_complement_stage2 <= ~duty_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三阶段：计算比较结果
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            add_result_stage3 <= 0;
            comparison_result_stage3 <= 0;
            valid_stage3 <= 0;
        end else begin
            add_result_stage3 <= counter_stage2 + duty_complement_stage2 + 1'b1;
            comparison_result_stage3 <= ((counter_stage2 + duty_complement_stage2 + 1'b1) & 
                                        (1 << ($clog2(PERIOD)-1))) != 0;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 最终输出
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            clk_out <= 0;
        end else if (valid_stage3) begin
            clk_out <= comparison_result_stage3 ? 1'b0 : 1'b1;
        end
    end
endmodule