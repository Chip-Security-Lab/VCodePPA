//SystemVerilog
module johnson_counter(
    input  wire       clk,    // 时钟输入
    input  wire       reset,  // 复位信号
    output reg  [3:0] q       // 计数器输出
);
    // 管道阶段寄存器
    reg [3:0] q_stage1;  // 第一级管道寄存器
    reg [3:0] q_stage2;  // 第二级管道寄存器
    
    // 第1阶段: 生成下一状态逻辑
    always @(posedge clk or posedge reset) begin
        if (reset)
            q_stage1 <= 4'b0000;
        else
            q_stage1 <= {q[2:0], ~q[3]}; // 将MSB取反后送到LSB
    end
    
    // 第2阶段: 中间处理阶段
    always @(posedge clk or posedge reset) begin
        if (reset)
            q_stage2 <= 4'b0000;
        else
            q_stage2 <= q_stage1;
    end
    
    // 输出阶段: 更新输出寄存器
    always @(posedge clk or posedge reset) begin
        if (reset)
            q <= 4'b0000;
        else
            q <= q_stage2;
    end
endmodule