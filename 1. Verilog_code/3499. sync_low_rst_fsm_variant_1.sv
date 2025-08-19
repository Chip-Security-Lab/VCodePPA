//SystemVerilog
module sync_low_rst_fsm(
    input wire clk,
    input wire rst_n,
    input wire trigger,
    output reg state_out
);
    // 状态定义
    localparam IDLE = 1'b0;
    localparam ACTIVE = 1'b1;
    
    // 流水线阶段信号
    reg trigger_stage1;
    reg valid_stage1;
    reg trigger_stage2;
    reg valid_stage2;
    
    // 状态寄存器
    reg state;
    reg state_stage1;
    reg state_stage2;
    
    // 预计算信号
    wire next_state;
    
    // 第一级流水线 - 输入采样和状态预计算
    always @(posedge clk) begin
        if (!rst_n) begin
            trigger_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            state_stage1 <= IDLE;
        end
        else begin
            trigger_stage1 <= trigger;
            valid_stage1 <= 1'b1;
            state_stage1 <= state;
        end
    end
    
    // 状态转换逻辑 - 移至流水线第一级和第二级之间
    assign next_state = trigger_stage1 ? ACTIVE : IDLE;
    
    // 第二级流水线 - 状态更新和输出预计算
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            trigger_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            state_stage2 <= IDLE;
        end
        else begin
            if (valid_stage1) begin
                state <= next_state;
                trigger_stage2 <= trigger_stage1;
                valid_stage2 <= valid_stage1;
                state_stage2 <= next_state;
            end
        end
    end
    
    // 第三级流水线 - 输出计算和寄存器化
    always @(posedge clk) begin
        if (!rst_n) begin
            state_out <= 1'b0;
        end
        else begin
            if (valid_stage2) begin
                state_out <= (state_stage2 == ACTIVE);
            end
        end
    end
endmodule