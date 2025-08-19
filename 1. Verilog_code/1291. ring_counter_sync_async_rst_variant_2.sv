//SystemVerilog
// 顶层模块
module ring_counter_sync_async_rst (
    input clk,      // 时钟信号
    input rst_n,    // 低电平有效的异步复位
    output [3:0] cnt // 环形计数器输出
);
    wire [3:0] next_count;
    
    // 实例化子模块 - 注意逻辑模块直接连接到输出
    counter_logic_with_reg u_logic_reg (
        .clk(clk),
        .rst_n(rst_n),
        .next_count(next_count),
        .current_count(cnt)
    );
    
    // 前向寄存器重定时 - 逻辑模块计算下一状态并直接连接到输入寄存器
    counter_input_stage u_input_stage (
        .current_count(cnt),
        .next_count(next_count)
    );
    
endmodule

// 计数器逻辑与寄存器集成模块 - 将寄存器移到逻辑之后
module counter_logic_with_reg (
    input clk,
    input rst_n,
    input [3:0] next_count,
    output reg [3:0] current_count
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_count <= 4'b0001; // 复位状态
        else
            current_count <= next_count;
    end
endmodule

// 计数器输入逻辑子模块 - 负责下一状态逻辑
module counter_input_stage (
    input [3:0] current_count,
    output [3:0] next_count
);
    // 环形计数: {current_count[0], current_count[3:1]}
    assign next_count = {current_count[0], current_count[3:1]};
endmodule