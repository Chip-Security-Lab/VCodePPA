//SystemVerilog
`timescale 1ns / 1ps

module t_ff_async_reset (
    input wire clk,    // 时钟信号
    input wire rst_n,  // 异步复位信号，低电平有效
    input wire t,      // T输入（触发信号）
    output wire q      // 输出信号
);
    // 内部连线
    wire next_state;
    
    // 实例化子模块
    next_state_logic next_state_unit (
        .t(t),
        .current_q(q),
        .next_q(next_state)
    );
    
    state_register state_reg_unit (
        .clk(clk),
        .rst_n(rst_n),
        .d(next_state),
        .q(q)
    );
    
endmodule

module next_state_logic (
    input wire t,          // 触发信号
    input wire current_q,  // 当前状态
    output reg next_q      // 下一状态，改为reg类型以支持if-else赋值
);
    // T触发器的组合逻辑：当t=1时翻转，当t=0时保持
    // 将条件运算符转换为if-else结构
    always @(*) begin
        if (t) begin
            next_q = ~current_q;  // 当t=1时翻转
        end else begin
            next_q = current_q;   // 当t=0时保持
        end
    end
    
endmodule

module state_register (
    input wire clk,    // 时钟信号
    input wire rst_n,  // 异步复位信号，低电平有效
    input wire d,      // 数据输入
    output reg q       // 状态输出
);
    // 带异步复位的状态寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;  // 复位时将输出置为0
        else
            q <= d;     // 否则加载新状态
    end
    
endmodule