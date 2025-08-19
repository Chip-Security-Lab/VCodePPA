//SystemVerilog
module fsm_divider (
    input wire clk_input,
    input wire reset,
    output wire clk_output
);
    // 流水线状态寄存器 - One-hot 编码
    reg [3:0] state_stage1, state_stage2;
    reg [3:0] next_state_stage1, next_state_stage2;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    
    // 状态定义 - One-hot 编码
    localparam S0 = 4'b0001, S1 = 4'b0010, 
               S2 = 4'b0100, S3 = 4'b1000;
    
    // 第一级流水线 - 状态计算
    always @(posedge clk_input) begin
        if (reset) begin
            state_stage1 <= S0;
            valid_stage1 <= 1'b0;
        end
        else begin
            state_stage1 <= next_state_stage1;
            valid_stage1 <= 1'b1;
        end
    end
    
    // 第一级流水线 - 组合逻辑
    always @(*) begin
        case(state_stage1)
            S0: next_state_stage1 = S1;
            S1: next_state_stage1 = S2;
            S2: next_state_stage1 = S3;
            S3: next_state_stage1 = S0;
            default: next_state_stage1 = S0;
        endcase
    end
    
    // 第二级流水线 - 状态传递和输出计算
    always @(posedge clk_input) begin
        if (reset) begin
            state_stage2 <= S0;
            valid_stage2 <= 1'b0;
        end
        else begin
            state_stage2 <= state_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出逻辑 - 流水线最后级
    wire output_condition;
    assign output_condition = (state_stage2[0] | state_stage2[1]); // S0 或 S1
    
    // 只有在有效时才输出
    assign clk_output = valid_stage2 ? output_condition : 1'b0;
    
endmodule