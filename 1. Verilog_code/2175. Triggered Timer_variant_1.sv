//SystemVerilog IEEE 1364-2005
module triggered_timer #(parameter CNT_W = 32)(
    input wire clock, n_reset, trigger,
    input wire [CNT_W-1:0] target,
    output reg [CNT_W-1:0] counter,
    output reg complete
);
    localparam IDLE = 1'b0, COUNTING = 1'b1;
    
    // 触发信号检测流水线 - 阶段1&2
    reg trigger_stage1, trigger_stage2;
    reg trig_d1;
    reg trig_rising_stage1;
    
    // 状态和计数管理流水线
    reg state_stage1, state_stage2;
    reg [CNT_W-1:0] counter_stage1;
    reg complete_stage1;
    
    // 计算阶段分解
    reg [CNT_W/2-1:0] counter_low_add;
    reg counter_high_carry;
    reg [CNT_W/2-1:0] counter_high_add;
    
    // 比较器流水线
    reg target_match_stage1;
    reg [(CNT_W/2)-1:0] target_low, target_high;
    reg [(CNT_W/2)-1:0] counter_low, counter_high;
    reg low_match, high_match;
    
    // 第一级流水线 - 触发检测
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            trigger_stage1 <= 1'b0;
            trig_d1 <= 1'b0;
            trig_rising_stage1 <= 1'b0;
        end else begin
            trigger_stage1 <= trigger;
            trig_d1 <= trigger_stage1;
            trig_rising_stage1 <= trigger_stage1 & ~trig_d1;
        end
    end
    
    // 第二级流水线 - 触发传播
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            trigger_stage2 <= 1'b0;
        end else begin
            trigger_stage2 <= trig_rising_stage1;
        end
    end
    
    // 状态机流水线 - 阶段1
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            state_stage1 <= IDLE;
            counter_low <= {(CNT_W/2){1'b0}};
            counter_high <= {(CNT_W/2){1'b0}};
            target_low <= {(CNT_W/2){1'b0}};
            target_high <= {(CNT_W/2){1'b0}};
        end else begin
            // 目标值分割
            target_low <= target[CNT_W/2-1:0];
            target_high <= target[CNT_W-1:CNT_W/2];
            
            case (state_stage1)
                IDLE: begin
                    if (trigger_stage2) begin 
                        state_stage1 <= COUNTING; 
                        counter_low <= {(CNT_W/2){1'b0}};
                        counter_high <= {(CNT_W/2){1'b0}};
                    end
                end
                COUNTING: begin
                    // 拆分加法操作为两级
                    if (target_match_stage1) begin
                        state_stage1 <= IDLE;
                    end else begin
                        // 低位递增逻辑
                        counter_low_add <= counter_low + 1'b1;
                        counter_high_carry <= (counter_low == {(CNT_W/2){1'b1}});
                    end
                end
            endcase
        end
    end
    
    // 计数器加法流水线 - 阶段2
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            counter_low <= {(CNT_W/2){1'b0}};
            counter_high <= {(CNT_W/2){1'b0}};
            counter_high_add <= {(CNT_W/2){1'b0}};
        end else if (state_stage1 == COUNTING && !target_match_stage1) begin
            counter_low <= counter_low_add;
            counter_high_add <= counter_high + counter_high_carry;
            counter_high <= counter_high_add;
        end
    end
    
    // 比较器流水线 - 阶段1
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            low_match <= 1'b0;
            high_match <= 1'b0;
        end else begin
            // 拆分比较操作
            low_match <= (counter_low == target_low - 1'b1);
            high_match <= (counter_high == target_high);
        end
    end
    
    // 比较器流水线 - 阶段2
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            target_match_stage1 <= 1'b0;
        end else begin
            target_match_stage1 <= low_match & high_match;
        end
    end
    
    // 状态机流水线 - 阶段2
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            state_stage2 <= IDLE;
            complete_stage1 <= 1'b0;
        end else begin
            state_stage2 <= state_stage1;
            
            if (state_stage1 == COUNTING && target_match_stage1) begin
                complete_stage1 <= 1'b1;
            end else begin
                complete_stage1 <= 1'b0;
            end
        end
    end
    
    // 最终输出寄存器
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            counter <= {CNT_W{1'b0}};
            complete <= 1'b0;
        end else begin
            counter <= {counter_high, counter_low};
            complete <= complete_stage1;
        end
    end
endmodule