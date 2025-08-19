//SystemVerilog
module triggered_timer #(parameter CNT_W = 32)(
    input wire clock, n_reset, trigger,
    input wire [CNT_W-1:0] target,
    output reg [CNT_W-1:0] counter,
    output reg complete
);
    localparam IDLE = 1'b0, COUNTING = 1'b1;
    reg state;
    reg trigger_reg;
    wire trig_rising;
    reg [CNT_W-1:0] target_reg;
    wire [CNT_W-1:0] target_minus_one;
    
    // 寄存输入信号，减少输入到第一级寄存器的延迟
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            trigger_reg <= 1'b0;
            target_reg <= {CNT_W{1'b0}};
        end else begin
            trigger_reg <= trigger;
            target_reg <= target;
        end
    end
    
    // 检测上升沿 - 移动到输入寄存器之后
    reg trigger_reg_d;
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            trigger_reg_d <= 1'b0;
        end else begin
            trigger_reg_d <= trigger_reg;
        end
    end
    
    // 使用输入寄存器后的信号检测上升沿
    assign trig_rising = trigger_reg & ~trigger_reg_d;
    
    // 使用寄存的目标值计算目标减一
    assign target_minus_one = target_reg + {CNT_W{1'b1}};
    
    // 主状态机逻辑
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            state <= IDLE;
            counter <= {CNT_W{1'b0}};
            complete <= 1'b0;
        end else case (state)
            IDLE: begin
                complete <= 1'b0;
                if (trig_rising) begin
                    state <= COUNTING;
                    counter <= {CNT_W{1'b0}};
                end
            end
            COUNTING: begin
                counter <= counter + 1'b1;
                if (counter == target_minus_one) begin
                    state <= IDLE;
                    complete <= 1'b1;
                end
            end
        endcase
    end
endmodule