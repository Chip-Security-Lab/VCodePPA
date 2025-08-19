//SystemVerilog
module FIR #(parameter W=8) (
    input clk, 
    input [W-1:0] sample,
    output reg [W+3:0] y
);
    // 定义系数作为单独参数
    parameter [3:0] COEFFS = 4'hA;
    
    // 用于存储样本值的移位寄存器链
    reg [W-1:0] delay_line [0:2];
    // 将延迟线从4级减少为3级，因为第一个样本直接用于计算
    wire [W-1:0] current_sample;
    reg [W+1:0] partial_sums [0:1]; // 用于存储部分和的寄存器
    
    // 使用线网直接获取当前样本值，减少输入到第一级寄存器的延迟
    assign current_sample = sample;
    
    always @(posedge clk) begin
        // 移位延迟线
        delay_line[0] <= current_sample;
        delay_line[1] <= delay_line[0];
        delay_line[2] <= delay_line[1];
        
        // 将累加计算分成流水线阶段，第一阶段
        partial_sums[0] <= (current_sample * COEFFS[0]) + 
                           (delay_line[0] * COEFFS[1]);
        
        // 第二阶段
        partial_sums[1] <= partial_sums[0] + 
                          (delay_line[1] * COEFFS[2]) + 
                          (delay_line[2] * COEFFS[3]);
        
        // 最终输出
        y <= partial_sums[1];
    end
endmodule