//SystemVerilog
module tapped_ring_counter(
    input wire clock,
    input wire reset,
    input wire enable,  // 流水线启动信号
    output reg [3:0] state,
    output wire tap1, tap2, // Tapped outputs
    output reg valid_out    // 指示输出有效
);
    // 流水线阶段寄存器
    reg [3:0] state_stage1, state_stage2;
    reg tap1_stage1, tap1_stage2;
    reg tap2_stage1, tap2_stage2;
    reg valid_stage1, valid_stage2;
    
    // 流水线阶段1：计算下一状态
    reg [3:0] next_state;
    
    always @(*) begin
        if (reset)
            next_state = 4'b0001;
        else
            next_state = {state[2:0], state[3]};
    end
    
    // 流水线控制逻辑
    always @(posedge clock) begin
        if (reset) begin
            // 重置所有流水线寄存器
            state_stage1 <= 4'b0000;
            tap1_stage1 <= 1'b0;
            tap2_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            
            state_stage2 <= 4'b0000;
            tap1_stage2 <= 1'b0;
            tap2_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            
            state <= 4'b0000;
            valid_out <= 1'b0;
        end
        else if (enable) begin
            // 流水线阶段1：状态计算与预处理
            state_stage1 <= next_state;
            tap1_stage1 <= next_state[1];
            tap2_stage1 <= next_state[3];
            valid_stage1 <= 1'b1;
            
            // 流水线阶段2：数据处理
            state_stage2 <= state_stage1;
            tap1_stage2 <= tap1_stage1;
            tap2_stage2 <= tap2_stage1;
            valid_stage2 <= valid_stage1;
            
            // 输出阶段：最终状态和输出
            state <= state_stage2;
            valid_out <= valid_stage2;
        end
    end
    
    // 定义输出taps，使用最后一级流水线的值
    assign tap1 = tap1_stage2;
    assign tap2 = tap2_stage2;
    
endmodule