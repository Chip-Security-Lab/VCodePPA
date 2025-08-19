//SystemVerilog - IEEE 1364-2005
module cascaded_timer (
    input wire clk_i,
    input wire rst_n_i,
    input wire enable_i,
    input wire [7:0] timer1_max_i,
    input wire [7:0] timer2_max_i,
    output wire timer1_tick_o,
    output wire timer2_tick_o
);
    // Stage 1: 第一个定时器计数和比较
    reg [7:0] timer1_count_stage1;
    reg [7:0] timer1_max_stage1;
    reg enable_stage1;
    reg timer1_terminal_stage1;
    
    // Stage 2: 第一个定时器输出和第二个定时器计数
    reg timer1_tick_stage2;
    reg [7:0] timer2_count_stage2;
    reg [7:0] timer2_max_stage2;
    reg timer2_terminal_stage2;
    
    // Stage 3: 第二个定时器输出
    reg timer2_tick_stage3;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    
    // 输出分配
    assign timer1_tick_o = timer1_tick_stage2;
    assign timer2_tick_o = timer2_tick_stage3;
    
    // Stage 1: 计算第一个定时器状态和结果
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            timer1_count_stage1 <= 8'd0;
            timer1_max_stage1 <= 8'd0;
            enable_stage1 <= 1'b0;
            timer1_terminal_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            // 锁存输入值
            timer1_max_stage1 <= timer1_max_i;
            enable_stage1 <= enable_i;
            valid_stage1 <= 1'b1;
            
            // 计算第一个定时器
            if (enable_i) begin
                // 预先计算终止条件
                timer1_terminal_stage1 <= (timer1_count_stage1 == timer1_max_i - 1'b1);
                
                // 更新计数器
                if (timer1_count_stage1 == timer1_max_i - 1'b1) begin
                    timer1_count_stage1 <= 8'd0;
                end else begin
                    timer1_count_stage1 <= timer1_count_stage1 + 1'b1;
                end
            end
        end
    end
    
    // Stage 2: 第一个定时器输出和第二个定时器计算
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            timer1_tick_stage2 <= 1'b0;
            timer2_count_stage2 <= 8'd0;
            timer2_max_stage2 <= 8'd0;
            timer2_terminal_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            // 第一个定时器输出
            timer1_tick_stage2 <= timer1_terminal_stage1 && enable_stage1;
            timer2_max_stage2 <= timer2_max_i;
            valid_stage2 <= valid_stage1;
            
            // 第二个定时器计算
            if (timer1_terminal_stage1 && enable_stage1) begin
                // 预先计算终止条件
                timer2_terminal_stage2 <= (timer2_count_stage2 == timer2_max_i - 1'b1);
                
                // 更新计数器
                if (timer2_count_stage2 == timer2_max_i - 1'b1) begin
                    timer2_count_stage2 <= 8'd0;
                end else begin
                    timer2_count_stage2 <= timer2_count_stage2 + 1'b1;
                end
            end
        end
    end
    
    // Stage 3: 第二个定时器输出
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            timer2_tick_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            timer2_tick_stage3 <= timer1_tick_stage2 && timer2_terminal_stage2;
        end
    end
endmodule