//SystemVerilog
module fsm_reset_sequencer(
    input wire clk,
    input wire trigger,
    output reg [3:0] reset_signals
);
    // Pipeline stage definitions
    localparam STAGE1 = 2'b00;
    localparam STAGE2 = 2'b01;
    localparam STAGE3 = 2'b10;
    localparam STAGE4 = 2'b11;

    // Pipeline control signals
    reg [1:0] state_stage1, state_stage2;
    reg trigger_stage1, trigger_stage2;
    reg valid_stage1, valid_stage2, valid_stage3;
    reg [3:0] reset_signals_stage1, reset_signals_stage2;
    
    // 优化后的状态转换表 - 预计算下一状态和输出，减少组合逻辑路径
    reg [1:0] next_state;
    reg [3:0] next_reset_signals;
    
    // 预计算下一状态和输出，平衡路径延迟
    always @(*) begin
        // 默认值设置，减少条件分支
        next_state = state_stage1;
        next_reset_signals = reset_signals_stage1;
        
        if (trigger) begin
            next_state = STAGE1;
            next_reset_signals = 4'b1111;
        end else begin
            case (state_stage1)
                STAGE1: begin 
                    next_state = STAGE2; 
                    next_reset_signals = 4'b0111; 
                end
                STAGE2: begin 
                    next_state = STAGE3; 
                    next_reset_signals = 4'b0011; 
                end
                STAGE3: begin 
                    next_state = STAGE4; 
                    next_reset_signals = 4'b0001; 
                end
                STAGE4: begin 
                    next_state = STAGE4; 
                    next_reset_signals = 4'b0000; 
                end
                default: begin 
                    next_state = STAGE1; 
                    next_reset_signals = 4'b1111; 
                end
            endcase
        end
    end

    // Stage 1: State calculation - 使用预计算结果
    always @(posedge clk) begin
        trigger_stage1 <= trigger;
        valid_stage1 <= 1'b1; // Always valid after reset
        state_stage1 <= next_state;
        reset_signals_stage1 <= next_reset_signals;
    end
    
    // Stage 2: Pipeline registers - 分割寄存器更新，减少关键路径
    always @(posedge clk) begin
        state_stage2 <= state_stage1;
        valid_stage2 <= valid_stage1;
    end
    
    always @(posedge clk) begin
        reset_signals_stage2 <= reset_signals_stage1;
        trigger_stage2 <= trigger_stage1;
    end
    
    // Stage 3: Output stage - 优化逻辑路径，减少等效门延迟
    reg [3:0] next_output;
    
    always @(*) begin
        if (!valid_stage2) begin
            next_output = reset_signals;  // 保持原值
        end else if (trigger_stage2) begin
            next_output = 4'b1111;
        end else begin
            next_output = reset_signals_stage2;
        end
    end
    
    always @(posedge clk) begin
        valid_stage3 <= valid_stage2;
        reset_signals <= next_output;
    end
endmodule