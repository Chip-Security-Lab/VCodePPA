//SystemVerilog
///////////////////////////////////////////////////////////
// Module: sync_low_rst_fsm
// 优化: 重组数据流路径，建立清晰的流水线结构，平衡时序与资源
///////////////////////////////////////////////////////////
module sync_low_rst_fsm(
    input  wire clk,
    input  wire rst_n,
    input  wire trigger,
    output reg  state_out
);
    // 状态参数定义
    localparam IDLE   = 1'b0;
    localparam ACTIVE = 1'b1;
    
    // 主状态流水线 - 第一级：当前状态
    reg current_state;
    
    // 流水线中间级 - 用于分割长路径
    reg trigger_stage1;
    reg state_condition;
    
    // 流水线最终级 - 下一状态计算结果
    reg next_state;
    
    // 数据通路状态缓存 - 减少关键扇出负载
    reg idle_indication;
    
    // 触发信号流水线寄存器 - 分割输入到逻辑的路径
    always @(posedge clk) begin
        if (!rst_n)
            trigger_stage1 <= 1'b0;
        else
            trigger_stage1 <= trigger;
    end
    
    // 状态条件计算 - 流水线中间级
    always @(posedge clk) begin
        if (!rst_n)
            state_condition <= 1'b0;
        else
            state_condition <= (current_state == IDLE) ? trigger_stage1 : !trigger_stage1;
    end
    
    // IDLE状态指示寄存器 - 减少IDLE常量的扇出负载
    always @(posedge clk) begin
        if (!rst_n)
            idle_indication <= IDLE;
        else
            idle_indication <= IDLE;
    end
    
    // 主状态转移逻辑 - 流水线化的状态计算
    always @(posedge clk) begin
        if (!rst_n) begin
            current_state <= IDLE;
            next_state <= IDLE;
        end
        else begin
            current_state <= next_state;
            next_state <= (current_state == IDLE) ? 
                         (state_condition ? ACTIVE : idle_indication) : 
                         (state_condition ? idle_indication : ACTIVE);
        end
    end
    
    // 输出逻辑 - 增加输出缓冲级
    always @(posedge clk) begin
        if (!rst_n)
            state_out <= 1'b0;
        else
            state_out <= (current_state == ACTIVE);
    end
endmodule