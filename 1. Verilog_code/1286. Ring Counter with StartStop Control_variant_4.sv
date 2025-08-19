//SystemVerilog
module controlled_ring_counter(
    input  wire       clock,
    input  wire       reset,
    input  wire       run,   // Start/stop control
    output wire [3:0] state
);
    wire       running;
    wire       next_running;
    wire [3:0] next_state;
    
    // 实例化控制单元子模块
    control_unit control_inst (
        .reset        (reset),
        .run          (run),
        .running      (running),
        .next_running (next_running)
    );
    
    // 实例化状态生成器子模块
    state_generator state_gen_inst (
        .reset        (reset),
        .running      (running),
        .run          (run),
        .current_state(state),
        .next_state   (next_state)
    );
    
    // 实例化状态寄存器子模块
    state_register state_reg_inst (
        .clock        (clock),
        .reset        (reset),
        .next_running (next_running),
        .next_state   (next_state),
        .running      (running),
        .state        (state)
    );
endmodule

// 控制单元 - 处理运行状态控制逻辑
module control_unit (
    input  wire reset,
    input  wire run,
    input  wire running,
    output wire next_running
);
    // 根据当前状态确定下一个running值
    assign next_running = (reset) ? 1'b0 :
                         (run) ? 1'b1 :
                         1'b0;
endmodule

// 状态生成器 - 计算下一个状态值
module state_generator (
    input  wire       reset,
    input  wire       running,
    input  wire       run,
    input  wire [3:0] current_state,
    output wire [3:0] next_state
);
    // 确定下一个状态值
    wire should_rotate = (reset) ? 1'b0 : 
                         ((running && run) || (running && !run)) ? 1'b1 : 
                         1'b0;
    
    // 状态轮转逻辑
    wire [3:0] rotated_state = {current_state[2:0], current_state[3]};
    
    // 选择重置值或轮转值
    assign next_state = (reset) ? 4'b0001 :
                       (should_rotate) ? rotated_state :
                       current_state;
endmodule

// 状态寄存器 - 保存系统状态
module state_register (
    input  wire       clock,
    input  wire       reset,
    input  wire       next_running,
    input  wire [3:0] next_state,
    output reg        running,
    output reg  [3:0] state
);
    // 时序逻辑更新状态
    always @(posedge clock) begin
        running <= next_running;
        state <= next_state;
    end
endmodule