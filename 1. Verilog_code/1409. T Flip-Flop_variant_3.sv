//SystemVerilog
module t_flip_flop (
    input wire clk,
    input wire rst_n,   // 添加复位信号
    input wire t,
    input wire valid_in, // 输入有效信号
    output wire valid_out, // 输出有效信号
    output reg q
);
    // 流水线寄存器和控制信号
    reg t_stage1;
    reg valid_stage1;
    reg q_stage1;
    
    // 第一级流水线：捕获输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            q_stage1 <= 1'b0;
        end
        else begin
            t_stage1 <= t;
            valid_stage1 <= valid_in;
            q_stage1 <= q; // 保存当前状态用于下一级计算
        end
    end
    
    // 第二级流水线：计算并更新输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 1'b0;
        end
        else if (valid_stage1) begin
            if (t_stage1) begin
                q <= ~q_stage1;
            end
            else begin
                q <= q_stage1;
            end
        end
    end
    
    // 传递有效信号
    reg valid_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end
        else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    assign valid_out = valid_stage2;
    
endmodule