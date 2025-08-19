//SystemVerilog
module rising_edge_t_ff (
    input wire clk,
    input wire rst_n,
    input wire t,
    input wire valid_in,
    output reg q,
    output reg valid_out
);
    // 优化的上升沿检测和翻转触发器流水线实现
    
    // 第一级流水线寄存器
    reg t_curr, t_prev;
    reg valid_stage1;
    
    // 第二级流水线寄存器  
    reg edge_detected;
    reg valid_stage2;
    
    // 第一级流水线 - 采样输入和上升沿检测准备
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t_curr <= 1'b0;
            t_prev <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            t_curr <= t;        // 采样当前输入
            t_prev <= t_curr;   // 保存前一个值用于边沿检测
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线 - 执行边沿检测逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_detected <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            // 优化的上升沿检测 - 直接从信号转换推断
            edge_detected <= t_curr & ~t_prev;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出级 - 条件状态翻转
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            // 只在有效上升沿时翻转，使用简化条件逻辑
            q <= q ^ (valid_stage2 & edge_detected);
            valid_out <= valid_stage2;
        end
    end
endmodule