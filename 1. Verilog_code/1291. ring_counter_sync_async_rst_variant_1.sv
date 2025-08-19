//SystemVerilog (IEEE 1364-2005)
// 顶层模块
module ring_counter_sync_async_rst (
    input clk,
    input rst_n,
    output [3:0] cnt
);
    // 状态信号
    wire [3:0] current_state;
    wire [3:0] next_state;
    
    // 缓冲时钟和状态信号
    wire clk_buf1, clk_buf2;
    wire [3:0] current_state_buf1, current_state_buf2;
    wire [3:0] next_state_buf;
    
    // 时钟缓冲以降低扇出负载
    assign clk_buf1 = clk;
    assign clk_buf2 = clk;
    
    // 当前状态缓冲
    assign current_state_buf1 = current_state;
    assign current_state_buf2 = current_state;
    
    // 下一状态缓冲
    assign next_state_buf = next_state;
    
    // 实例化子模块
    next_state_logic next_state_gen (
        .current_state(current_state_buf1),
        .next_state(next_state)
    );
    
    state_register state_reg (
        .clk(clk_buf1),
        .rst_n(rst_n),
        .next_state(next_state_buf),
        .current_state(current_state)
    );
    
    // 输出赋值
    assign cnt = current_state_buf2;
    
endmodule

// 下一状态逻辑子模块
module next_state_logic (
    input [3:0] current_state,
    output [3:0] next_state
);
    // 环形计数器的下一状态逻辑：位循环
    assign next_state = {current_state[0], current_state[3:1]};
    
endmodule

// 状态寄存器子模块
module state_register (
    input clk,
    input rst_n,
    input [3:0] next_state,
    output reg [3:0] current_state
);
    // 状态存储与重置逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= 4'b0001; // 异步复位初始状态
        else
            current_state <= next_state;
    end
    
endmodule