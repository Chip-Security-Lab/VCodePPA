//SystemVerilog
// 顶层模块
module t_ff_sync_reset (
    input wire clock,
    input wire reset,
    input wire toggle,
    output wire q_out
);
    // 内部连线
    wire next_state;
    wire toggle_pipelined;
    wire current_state_pipelined;
    
    // 流水线寄存器 - 为输入信号添加寄存器以减少组合逻辑路径
    toggle_pipeline input_pipeline (
        .clock(clock),
        .reset(reset),
        .toggle_in(toggle),
        .current_state_in(q_out),
        .toggle_out(toggle_pipelined),
        .current_state_out(current_state_pipelined)
    );
    
    // 状态逻辑子模块实例化 - 使用流水线后的信号
    tff_next_state_logic state_logic (
        .toggle(toggle_pipelined),
        .current_state(current_state_pipelined),
        .next_state(next_state)
    );
    
    // 状态寄存器子模块实例化
    tff_state_register state_reg (
        .clock(clock),
        .reset(reset),
        .next_state(next_state),
        .current_state(q_out)
    );
    
endmodule

// 流水线寄存器模块 - 为关键路径增加寄存器级
module toggle_pipeline (
    input wire clock,
    input wire reset,
    input wire toggle_in,
    input wire current_state_in,
    output reg toggle_out,
    output reg current_state_out
);
    always @(posedge clock) begin
        if (reset) begin
            toggle_out <= 1'b0;
            current_state_out <= 1'b0;
        end
        else begin
            toggle_out <= toggle_in;
            current_state_out <= current_state_in;
        end
    end
endmodule

// 组合逻辑子模块 - 计算下一状态
module tff_next_state_logic (
    input wire toggle,
    input wire current_state,
    output wire next_state
);
    // 参数化设计，提高可复用性
    parameter INVERT_LOGIC = 1'b0;
    
    // 翻转逻辑，根据toggle输入决定是否翻转当前状态
    assign next_state = toggle ? (current_state ^ ~INVERT_LOGIC) : current_state;
    
endmodule

// 时序逻辑子模块 - 状态寄存器
module tff_state_register (
    input wire clock,
    input wire reset,
    input wire next_state,
    output reg current_state
);
    // 参数化复位值，提高可复用性
    parameter RESET_VALUE = 1'b0;
    
    // 同步复位的状态寄存器
    always @(posedge clock) begin
        if (reset)
            current_state <= RESET_VALUE;
        else
            current_state <= next_state;
    end
    
endmodule