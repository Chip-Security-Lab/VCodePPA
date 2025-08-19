//SystemVerilog
module tff_clear (
    input  wire clk,       // 时钟信号
    input  wire clr,       // 清零信号
    input  wire valid_in,  // 输入有效信号
    output wire valid_out, // 输出有效信号
    output reg  q          // 输出触发器状态
);

    // 优化后的流水线设计，应用前向寄存器重定时
    // 将靠近输入的寄存器向前移动，穿过组合逻辑
    
    // 第一阶段: 直接处理输入，不缓存输入
    wire next_q_value;     // 计算的下一个q值，直接组合逻辑连接
    
    // 第二阶段: 中间处理
    reg valid_pipe2;       // 第二阶段有效信号
    reg q_pipe2;           // 第二阶段q值
    
    // 第三阶段: 输出处理
    reg valid_pipe3;       // 第三阶段有效信号（输出有效）
    
    // 将输入计算部分改为组合逻辑
    // 移除了第一级流水线寄存器，直接用组合逻辑计算next_q_value
    assign next_q_value = valid_in ? ~q : q;
    
    // 第二级流水线 - 现在作为第一级寄存器
    // 将输入直接传递到这一级
    always @(posedge clk) begin
        if (clr) begin
            valid_pipe2 <= 1'b0;
            q_pipe2     <= 1'b0;
        end
        else begin
            valid_pipe2 <= valid_in;  // 直接使用输入信号
            
            // 直接使用组合逻辑的结果
            if (valid_in)
                q_pipe2 <= next_q_value;
            else
                q_pipe2 <= q_pipe2;
        end
    end
    
    // 第三级流水线 - 输出处理阶段
    always @(posedge clk) begin
        if (clr) begin
            q <= 1'b0;
            valid_pipe3 <= 1'b0;
        end
        else begin
            valid_pipe3 <= valid_pipe2;
            
            // 更新最终输出
            if (valid_pipe2)
                q <= q_pipe2;
            else
                q <= q;
        end
    end
    
    // 输出有效信号连接
    assign valid_out = valid_pipe3;

endmodule