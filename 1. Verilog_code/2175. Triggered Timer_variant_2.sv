//SystemVerilog
module triggered_timer #(parameter CNT_W = 32)(
    input wire clock, n_reset, trigger,
    input wire [CNT_W-1:0] target,
    output reg [CNT_W-1:0] counter,
    output reg complete
);
    localparam IDLE = 1'b0, COUNTING = 1'b1;
    reg state;
    reg trig_d1, trig_d2;
    wire trig_rising;
    // 提前计算计数器是否达到目标值的条件
    wire counter_at_target;
    wire [CNT_W-1:0] next_counter;
    reg complete_pre;
    
    // 并行前缀减法器相关信号
    wire [CNT_W-1:0] target_minus_one;
    wire [CNT_W-1:0] ones_complement;
    wire [CNT_W-1:0] p_signals;
    wire [CNT_W-1:0] g_signals;
    wire [CNT_W:0] carry;
    
    // 触发信号检测逻辑保持不变
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin 
            trig_d1 <= 1'b0; 
            trig_d2 <= 1'b0; 
        end
        else begin 
            trig_d1 <= trigger; 
            trig_d2 <= trig_d1; 
        end
    end
    
    assign trig_rising = trig_d1 & ~trig_d2;
    
    // 计算下一个计数器值
    assign next_counter = (state == IDLE && trig_rising) ? {CNT_W{1'b0}} :
                          (state == COUNTING) ? counter + 1'b1 : counter;
    
    // 并行前缀减法器实现: target - 1
    // 步骤1: 计算被减数target的反码
    assign ones_complement = ~1'b1;  // 1的反码
    
    // 步骤2: 生成传播和生成信号
    assign p_signals = target ^ ones_complement;
    assign g_signals = target & ones_complement;
    
    // 步骤3: 计算前缀进位
    assign carry[0] = 1'b1; // 减法补码操作需要初始进位为1
    
    genvar i;
    generate
        for (i = 0; i < CNT_W; i = i + 1) begin : prefix_carry
            assign carry[i+1] = g_signals[i] | (p_signals[i] & carry[i]);
        end
    endgenerate
    
    // 步骤4: 计算最终结果
    assign target_minus_one = target ^ ones_complement ^ carry[CNT_W-1:0];
    
    // 提前计算目标达成条件 (使用并行前缀减法器计算结果)
    assign counter_at_target = (counter == target_minus_one) && (state == COUNTING);
    
    // 状态和计数器逻辑
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            state <= IDLE;
            counter <= {CNT_W{1'b0}};
            complete_pre <= 1'b0;
        end else begin
            counter <= next_counter;
            
            case (state)
                IDLE: begin
                    complete_pre <= 1'b0;
                    if (trig_rising) begin 
                        state <= COUNTING;
                    end
                end
                COUNTING: begin
                    if (counter_at_target) begin 
                        state <= IDLE;
                        complete_pre <= 1'b1;
                    end
                end
            endcase
        end
    end
    
    // 输出寄存器管道化
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            complete <= 1'b0;
        end else begin
            complete <= complete_pre;
        end
    end
endmodule