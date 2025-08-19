//SystemVerilog
module pwm_generator #(parameter CNT_W=8) (
    input clk, rst, 
    input [CNT_W-1:0] duty_cycle,
    output reg pwm_out
);

// 流水线寄存器
reg [CNT_W-1:0] cnt_stage1;
reg [CNT_W-1:0] duty_cycle_stage1;
reg compare_result_stage2;

// 第一级流水线 - 计数器和输入捕获
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cnt_stage1 <= 0;
        duty_cycle_stage1 <= 0;
    end else begin
        cnt_stage1 <= cnt_stage1 + 1;
        duty_cycle_stage1 <= duty_cycle;
    end
end

// 第二级流水线 - 比较逻辑
always @(posedge clk or posedge rst) begin
    if (rst) begin
        compare_result_stage2 <= 0;
    end else begin
        compare_result_stage2 <= (cnt_stage1 < duty_cycle_stage1);
    end
end

// 第三级流水线 - 输出寄存器
always @(posedge clk or posedge rst) begin
    if (rst) begin
        pwm_out <= 0;
    end else begin
        pwm_out <= compare_result_stage2;
    end
end

endmodule