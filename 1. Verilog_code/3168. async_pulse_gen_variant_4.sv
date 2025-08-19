//SystemVerilog
module async_pulse_gen(
    input clk,        // 添加时钟输入以实现更好的同步
    input data_in,    
    input reset,      
    output reg pulse_out  // 改为寄存器输出以改善时序
);
    // 数据流水线寄存器
    reg data_in_stage1;
    reg data_in_stage2;
    
    // 主数据路径 - 流水线化处理
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // 重置所有管道寄存器
            data_in_stage1 <= 1'b0;
            data_in_stage2 <= 1'b0;
            pulse_out <= 1'b0;
        end else begin
            // 流水线第一级 - 捕获输入
            data_in_stage1 <= data_in;
            
            // 流水线第二级 - 延迟一个周期
            data_in_stage2 <= data_in_stage1;
            
            // 脉冲检测逻辑 - 上升沿检测
            pulse_out <= data_in_stage1 & ~data_in_stage2;
        end
    end
endmodule