//SystemVerilog
// 顶层模块
module counter_onehot #(
    parameter BITS = 4
)(
    input wire clk,
    input wire rst,
    output wire [BITS-1:0] state
);
    // 内部信号
    wire [BITS-1:0] next_state_stage1;
    reg [BITS-1:0] current_state;
    reg [BITS-1:0] next_state_stage2;
    reg [BITS-1:0] next_state_stage3;
    
    // 子模块实例化
    next_state_generator #(
        .BITS(BITS)
    ) next_state_gen (
        .current_state(current_state),
        .next_state(next_state_stage1)
    );
    
    // 增加流水线阶段
    always @(posedge clk) begin
        if (rst) begin
            next_state_stage2 <= {BITS{1'b0}};
            next_state_stage3 <= {BITS{1'b0}};
        end else begin
            next_state_stage2 <= next_state_stage1;
            next_state_stage3 <= next_state_stage2;
        end
    end
    
    // 流水线状态寄存器更新
    always @(posedge clk) begin
        if (rst) 
            current_state <= {{(BITS-1){1'b0}}, 1'b1}; // 复位值为 one-hot 编码的初始值
        else 
            current_state <= next_state_stage3;
    end
    
    // 输出赋值
    assign state = current_state;
    
endmodule

// 下一状态生成子模块 - 流水线优化
module next_state_generator #(
    parameter BITS = 4
)(
    input wire [BITS-1:0] current_state,
    output reg [BITS-1:0] next_state
);
    // 拆分计算为多个部分，增加流水线深度
    wire [BITS/2-1:0] lower_half;
    wire [BITS/2-1:0] upper_half;
    reg [BITS/2-1:0] lower_half_stage1;
    reg [BITS/2-1:0] upper_half_stage1;
    
    // 实现循环移位逻辑，分阶段计算
    assign lower_half = current_state[BITS/2-1:0];
    assign upper_half = current_state[BITS-1:BITS/2];
    
    always @(*) begin
        // 第一流水线阶段 - 分段处理移位操作
        lower_half_stage1 = {lower_half[BITS/2-2:0], upper_half[BITS/2-1]};
        upper_half_stage1 = {upper_half[BITS/2-2:0], lower_half[BITS/2-1]};
        
        // 组合最终结果
        next_state = {upper_half_stage1, lower_half_stage1};
    end
    
endmodule