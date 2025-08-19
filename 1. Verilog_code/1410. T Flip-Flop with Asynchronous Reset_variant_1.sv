//SystemVerilog
// 顶层模块
module t_ff_async_reset (
    input  wire clk,    // 时钟信号
    input  wire rst_n,  // 异步低电平复位
    input  wire t,      // T输入
    output wire q       // 输出信号
);
    // 内部信号
    wire next_state;
    
    // 实例化状态计算子模块
    next_state_logic next_state_calc (
        .current_q(q),
        .t_input(t),
        .next_q(next_state)
    );
    
    // 实例化状态存储子模块
    state_storage state_reg (
        .clk(clk),
        .rst_n(rst_n),
        .next_state(next_state),
        .q(q)
    );
    
endmodule

// 状态计算子模块 - 纯组合逻辑
module next_state_logic (
    input  wire current_q,  // 当前状态
    input  wire t_input,    // T输入
    output wire next_q      // 下一状态
);
    // T=1时翻转，T=0时保持
    assign next_q = t_input ? ~current_q : current_q;
    
endmodule

// 状态存储子模块 - 时序逻辑
module state_storage (
    input  wire clk,        // 时钟信号
    input  wire rst_n,      // 异步低电平复位
    input  wire next_state, // 下一状态输入
    output reg  q           // 状态输出
);
    // 带异步复位的触发器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else
            q <= next_state;
    end
    
endmodule