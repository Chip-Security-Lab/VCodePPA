//SystemVerilog
// 顶层模块 - 重构后的时钟门控掩码控制器
module clk_gate_mask #(
    parameter MASK = 4'b1100
)(
    input  wire       clk,     // 系统时钟
    input  wire       en,      // 使能信号
    output wire [3:0] out      // 输出总线
);
    // 主数据通路信号定义
    wire [3:0] current_state;  // 当前状态值
    wire [3:0] mask_result;    // 掩码操作结果
    wire [3:0] next_state;     // 下一状态值
    reg        en_stage1;      // 使能信号流水线寄存器
    
    // 流水线第一级 - 使能信号寄存
    always @(posedge clk) begin
        en_stage1 <= en;
    end
    
    // 掩码处理 - 组合逻辑优化路径
    assign mask_result = current_state | MASK;
    
    // 下一状态选择器 - 减少逻辑深度
    assign next_state = en_stage1 ? mask_result : current_state;
    
    // 状态更新寄存器 - 流水线第二级
    state_register state_reg (
        .clk       (clk),
        .next_state(next_state),
        .state     (current_state)
    );
    
    // 输出驱动 - 独立输出缓冲
    output_buffer out_buf (
        .clk        (clk),
        .state_in   (current_state),
        .buffered_out(out)
    );
    
endmodule

// 状态寄存器模块 - 处理主要状态存储
module state_register (
    input  wire       clk,        // 系统时钟
    input  wire [3:0] next_state, // 下一状态输入
    output reg  [3:0] state       // 当前状态输出
);
    // 主状态寄存器
    always @(posedge clk) begin
        state <= next_state;
    end
    
endmodule

// 输出缓冲模块 - 提供稳定的输出信号
module output_buffer (
    input  wire       clk,         // 系统时钟
    input  wire [3:0] state_in,    // 状态输入
    output reg  [3:0] buffered_out // 缓冲输出
);
    // 输出缓冲寄存器 - 将主状态与输出隔离
    always @(posedge clk) begin
        buffered_out <= state_in;
    end
    
endmodule