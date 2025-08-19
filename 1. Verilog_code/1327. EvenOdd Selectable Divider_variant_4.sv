//SystemVerilog
module even_odd_divider (
    input wire CLK, 
    input wire RESET, 
    input wire ODD_DIV,
    output reg DIV_CLK
);
    // 阶段1寄存器信号定义
    reg [2:0] counter_stage1;
    reg half_cycle_stage1;
    reg div_clk_stage1;
    reg odd_div_stage1;
    
    // 阶段2寄存器信号定义
    reg [2:0] counter_stage2;
    reg half_cycle_stage2;
    reg div_clk_stage2;
    reg odd_div_stage2;
    reg terminal_count_stage2;
    
    // 组合逻辑部分 - 终端计数检测
    wire terminal_count_stage1;
    assign terminal_count_stage1 = odd_div_stage1 ? 
                    (counter_stage1 == 3'b100 && half_cycle_stage1) || (counter_stage1 == 3'b100 && !half_cycle_stage1) :
                    (counter_stage1 == 3'b100);
    
    // 组合逻辑部分 - 下一状态计算
    wire [2:0] next_counter_stage1;
    wire next_half_cycle_stage1;
    wire next_div_clk_stage1;
    
    assign next_counter_stage1 = terminal_count_stage1 ? 3'b000 : (counter_stage1 + 1'b1);
    assign next_half_cycle_stage1 = terminal_count_stage2 ? 
                                  (odd_div_stage2 ? ~half_cycle_stage2 : half_cycle_stage2) : 
                                  half_cycle_stage2;
    assign next_div_clk_stage1 = terminal_count_stage2 ? ~div_clk_stage2 : div_clk_stage2;
    
    // 时序逻辑部分 - 阶段1寄存器更新
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            counter_stage1 <= 3'b000;
            odd_div_stage1 <= 1'b0;
        end else begin
            counter_stage1 <= next_counter_stage1;
            odd_div_stage1 <= ODD_DIV;
        end
    end
    
    // 时序逻辑部分 - 阶段1到阶段2的传递
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            counter_stage2 <= 3'b000;
            half_cycle_stage2 <= 1'b0;
            div_clk_stage2 <= 1'b0;
            odd_div_stage2 <= 1'b0;
            terminal_count_stage2 <= 1'b0;
        end else begin
            counter_stage2 <= counter_stage1;
            half_cycle_stage2 <= half_cycle_stage1;
            div_clk_stage2 <= div_clk_stage1;
            odd_div_stage2 <= odd_div_stage1;
            terminal_count_stage2 <= terminal_count_stage1;
        end
    end
    
    // 时序逻辑部分 - 阶段2寄存器和输出更新
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            half_cycle_stage1 <= 1'b0;
            div_clk_stage1 <= 1'b0;
            DIV_CLK <= 1'b0;
        end else begin
            half_cycle_stage1 <= next_half_cycle_stage1;
            div_clk_stage1 <= next_div_clk_stage1;
            DIV_CLK <= next_div_clk_stage1;
        end
    end
endmodule