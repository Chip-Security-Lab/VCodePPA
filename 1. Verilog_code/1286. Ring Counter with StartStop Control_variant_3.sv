//SystemVerilog
module controlled_ring_counter(
    input  wire       clock,
    input  wire       reset,
    input  wire       run,    // Start/stop control
    output reg  [3:0] state
);
    // 数据流阶段1: 输入处理
    reg        run_d1;
    reg        run_d2;
    
    // 数据流阶段2: 状态控制
    reg        running_state;
    wire       next_running;
    
    // 数据流阶段3: 状态转换
    reg  [3:0] next_state;
    
    // 阶段1: 输入同步和预处理
    always @(posedge clock) begin
        if (reset) begin
            run_d1 <= 1'b0;
            run_d2 <= 1'b0;
        end
        else begin
            run_d1 <= run;     // 第一级输入寄存
            run_d2 <= run_d1;  // 第二级输入寄存，进一步稳定信号
        end
    end
    
    // 阶段2: 运行状态逻辑
    assign next_running = (run_d1 || running_state) && !reset && run_d2;
    
    always @(posedge clock) begin
        if (reset) begin
            running_state <= 1'b0;
        end
        else begin
            running_state <= next_running;
        end
    end
    
    // 阶段3: 状态计算
    always @(*) begin
        if (running_state)
            next_state = {state[2:0], state[3]};  // 循环移位
        else
            next_state = state;  // 保持当前状态
    end
    
    // 阶段4: 状态输出寄存器
    always @(posedge clock) begin
        if (reset) begin
            state <= 4'b0001;  // 复位初始状态
        end
        else begin
            state <= next_state;
        end
    end
    
endmodule