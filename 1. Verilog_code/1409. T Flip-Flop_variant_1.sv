//SystemVerilog
module t_flip_flop (
    input wire clk,
    input wire rst_n,    // 添加复位信号
    input wire t,
    input wire valid_in, // 输入有效信号
    output wire valid_out, // 输出有效信号
    output reg q
);
    // 流水线阶段1：捕获输入
    reg t_stage1;
    reg q_stage1;
    reg valid_stage1;
    
    // 流水线阶段2：计算
    reg t_stage2;
    reg q_stage2;
    reg valid_stage2;
    
    // 合并所有时钟域逻辑到单一always块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 流水线第一级复位
            t_stage1 <= 1'b0;
            q_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            
            // 流水线第二级复位
            t_stage2 <= 1'b0;
            q_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            
            // 输出复位
            q <= 1'b0;
        end else begin
            // 流水线第一级 - 输入捕获
            t_stage1 <= t;
            q_stage1 <= q;
            valid_stage1 <= valid_in;
            
            // 流水线第二级 - 计算逻辑
            t_stage2 <= t_stage1;
            q_stage2 <= t_stage1 ? ~q_stage1 : q_stage1;
            valid_stage2 <= valid_stage1;
            
            // 输出赋值
            if (valid_stage2) begin
                q <= q_stage2;
            end
        end
    end
    
    // 输出有效信号
    assign valid_out = valid_stage2;
    
endmodule