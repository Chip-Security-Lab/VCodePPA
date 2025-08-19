//SystemVerilog
// 顶层模块 - 重构的异步移位反馈系统
module async_shift_feedback #(
    parameter LENGTH = 8,
    parameter TAPS = 4'b1001
)(
    input logic clk,              // 添加时钟输入以支持流水线
    input logic rst_n,            // 添加复位信号以初始化流水线
    input logic data_in,
    input logic [LENGTH-1:0] current_reg,
    output logic next_bit,
    output logic [LENGTH-1:0] next_reg
);
    // 流水线寄存器和数据路径信号
    logic [LENGTH-1:0] current_reg_r1;        // 流水线第一级寄存器
    logic feedback, feedback_r1;              // 反馈信号及其寄存器
    logic [LENGTH-1:0] shifted_reg, shifted_reg_r1;  // 移位寄存器及其流水线寄存器
    logic parity_result;                      // 奇偶校验结果
    
    // 第一级流水线：输入注册和反馈计算
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_reg_r1 <= '0;
            feedback_r1 <= 1'b0;
        end else begin
            current_reg_r1 <= current_reg;
            feedback_r1 <= ^(current_reg & TAPS);  // 内联反馈计算，减少层次
        end
    end
    
    // 第二级流水线：计算移位和准备数据
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifted_reg_r1 <= '0;
        end else begin
            shifted_reg_r1 <= {current_reg_r1[LENGTH-2:0], 1'b0};  // 内联移位计算
        end
    end

    // 组合逻辑：计算奇偶校验结果
    assign parity_result = data_in ^ feedback_r1;
    
    // 最终输出计算
    assign next_reg = {shifted_reg_r1[LENGTH-1:1], parity_result};
    assign next_bit = parity_result;

endmodule