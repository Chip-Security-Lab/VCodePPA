//SystemVerilog
module usb_low_power_ctrl(
    input clk_48mhz,
    input reset_n,
    input bus_activity,
    input suspend_req,
    input resume_req,
    output reg suspend_state,
    output reg clk_en,
    output reg pll_en
);
    // 状态编码优化，使用单热编码以减少状态转换逻辑开销
    localparam [3:0] ACTIVE  = 4'b0001, 
                     IDLE    = 4'b0010, 
                     SUSPEND = 4'b0100, 
                     RESUME  = 4'b1000;
    
    reg [3:0] state, next_state;
    reg [15:0] idle_counter, next_idle_counter;
    reg next_suspend_state, next_clk_en, next_pll_en;
    
    // 使用时序/组合逻辑分离的两段式状态机结构
    // 时序逻辑 - 更新寄存器
    always @(posedge clk_48mhz or negedge reset_n) begin
        if (!reset_n) begin
            state <= ACTIVE;
            idle_counter <= 16'd0;
            suspend_state <= 1'b0;
            clk_en <= 1'b1;
            pll_en <= 1'b1;
        end else begin
            state <= next_state;
            idle_counter <= next_idle_counter;
            suspend_state <= next_suspend_state;
            clk_en <= next_clk_en;
            pll_en <= next_pll_en;
        end
    end
    
    // 组合逻辑 - 计算下一状态
    always @(*) begin
        // 默认保持当前值，减少不必要的赋值
        next_state = state;
        next_idle_counter = idle_counter;
        next_suspend_state = suspend_state;
        next_clk_en = clk_en;
        next_pll_en = pll_en;
        
        if (state == ACTIVE) begin
            if (bus_activity) begin
                next_idle_counter = 16'd0;
            end else begin
                next_idle_counter = idle_counter + 1'b1;
                // 优化比较逻辑：suspend_req优先判断以减少比较链长度
                if (suspend_req || (idle_counter >= 16'd3000)) begin
                    next_state = IDLE;
                end
            end
        end
        else if (state == IDLE) begin
            if (bus_activity) begin
                next_state = ACTIVE;
                next_idle_counter = 16'd0;
            end else begin
                // 将增量操作放到条件分支前，避免重复代码
                next_idle_counter = idle_counter + 1'b1;
                
                // 使用大于等于替代大于，优化比较器实现
                if (idle_counter >= 16'd20000) begin
                    next_state = SUSPEND;
                    next_suspend_state = 1'b1;
                    next_clk_en = 1'b0;
                    next_pll_en = 1'b0;
                end
            end
        end
        else if (state == SUSPEND) begin
            // 优化逻辑OR，使用短路求值特性
            if (resume_req || bus_activity) begin
                next_state = RESUME;
                next_pll_en = 1'b1;
                next_idle_counter = 16'd0; // 重置计数器
            end
        end
        else if (state == RESUME) begin
            // 使用小于等于替代小于，优化比较器实现
            if (idle_counter <= 16'd999) begin
                next_idle_counter = idle_counter + 1'b1;
            end else begin
                next_clk_en = 1'b1;
                next_state = ACTIVE;
                next_suspend_state = 1'b0;
                next_idle_counter = 16'd0;
            end
        end
        else begin
            // 安全状态转换，防止锁存器生成
            next_state = ACTIVE;
            next_idle_counter = 16'd0;
            next_suspend_state = 1'b0;
            next_clk_en = 1'b1;
            next_pll_en = 1'b1;
        end
    end
endmodule