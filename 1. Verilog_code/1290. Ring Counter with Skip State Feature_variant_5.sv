//SystemVerilog
//IEEE 1364-2005 Verilog
module skip_state_ring_counter(
    input wire clock,
    input wire reset,
    input wire skip, // Skip next state
    output reg [3:0] state
);
    // 流水线阶段信号
    reg [3:0] state_next;
    reg [3:0] state_stage1;
    reg [3:0] state_stage2;
    reg skip_stage1;
    reg skip_stage2;
    reg valid_stage1;
    reg valid_stage2;
    
    // 预计算可能的状态转换 - 减少关键路径
    always @(*) begin
        // 正常移位操作 - 提前计算
        state_next = {state[2:0], state[3]};
    end
    
    // 流水线第一级 - 状态和控制信号捕获
    always @(posedge clock) begin
        if (reset) begin
            state_stage1 <= 4'b0001;
            skip_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            state_stage1 <= state;
            skip_stage1 <= skip;
            valid_stage1 <= 1'b1;
        end
    end
    
    // 流水线第二级 - 状态变换（优化后的逻辑）
    always @(posedge clock) begin
        if (reset) begin
            state_stage2 <= 4'b0000;
            skip_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            skip_stage2 <= skip_stage1;
            valid_stage2 <= valid_stage1;
            
            // 重组组合逻辑以平衡路径延迟
            if (skip_stage1) begin
                // 跳过一个状态 - 简化计算
                state_stage2[3:2] <= state_stage1[1:0];
                state_stage2[1:0] <= state_stage1[3:2];
            end
            else begin
                // 使用预计算的结果，减少组合逻辑深度
                state_stage2 <= {state_stage1[2:0], state_stage1[3]};
            end
        end
    end
    
    // 流水线第三级 - 输出状态更新（简化逻辑）
    always @(posedge clock) begin
        if (reset) begin
            state <= 4'b0001; // 复位状态
        end
        else if (valid_stage2) begin
            // 直接使用计算好的状态
            state <= state_stage2;
        end
    end
endmodule