//SystemVerilog
module Timer_FSM_Control (
    input clk, rst, trigger,
    output reg done
);
    // 使用参数替代enum类型
    parameter IDLE = 1'b0, COUNTING = 1'b1;
    
    reg state, next_state;
    reg [7:0] cnt, next_cnt;
    
    // 寄存注册trigger信号，将输入寄存器向前推移
    reg trigger_reg;
    
    // 前向重定时：将触发器延迟一个周期
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            trigger_reg <= 1'b0;
        end else begin
            trigger_reg <= trigger;
        end
    end
    
    // 组合逻辑部分
    always @(*) begin
        // 默认值，减少逻辑深度
        next_state = state;
        next_cnt = cnt;
        
        case(state)
            IDLE: begin
                if (trigger_reg) begin
                    next_state = COUNTING;
                    next_cnt = 8'd100;
                end
            end
            COUNTING: begin
                // 预先计算条件，减少关键路径
                next_cnt = cnt - 8'd1;
                
                if (cnt == 8'd0) begin
                    next_state = IDLE;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // 时序逻辑部分
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            cnt <= 8'h00;
            done <= 1'b0;
        end else begin
            state <= next_state;
            cnt <= next_cnt;
            
            // 将done信号的计算移至这里，实现前向寄存重定时
            // 直接在时序块中判断cnt是否为1
            if (state == COUNTING && cnt == 8'd1) begin
                done <= 1'b1;
            end else if (state == IDLE && trigger_reg) begin
                done <= 1'b0;
            end
        end
    end
endmodule