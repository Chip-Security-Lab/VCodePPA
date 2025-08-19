//SystemVerilog
module pattern_mask_ismu(
    input clk, reset,
    input [7:0] interrupt,
    input [7:0] mask_pattern,
    input [2:0] pattern_sel,
    output reg [7:0] masked_interrupt
);
    reg [7:0] interrupt_reg;
    reg [7:0] mask_pattern_reg;
    reg [2:0] pattern_sel_reg;
    reg [7:0] effective_mask;
    
    // 使用非阻塞赋值注册输入信号
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            interrupt_reg <= 8'h00;
            mask_pattern_reg <= 8'h00;
            pattern_sel_reg <= 3'h0;
        end else begin
            interrupt_reg <= interrupt;
            mask_pattern_reg <= mask_pattern;
            pattern_sel_reg <= pattern_sel;
        end
    end
    
    // 掩码选择逻辑优化 - 使用更高效的实现
    always @(*) begin
        // 默认值设置
        effective_mask = 8'h00;
        
        // 单比特逻辑检查，减少case语句的复杂度
        if (pattern_sel_reg[2:1] == 2'b00) begin
            // 处理0和1的情况
            effective_mask = {8{pattern_sel_reg[0]}};  // 全0或全1掩码
        end else if (pattern_sel_reg[2:1] == 2'b01) begin
            // 处理2和3的情况
            effective_mask = {4{pattern_sel_reg[0], ~pattern_sel_reg[0]}};  // 上半或下半掩码
        end else if (pattern_sel_reg[2:1] == 2'b10) begin
            // 处理4和5的情况
            effective_mask = {4{pattern_sel_reg[0], ~pattern_sel_reg[0]}};  // 交替掩码
            effective_mask = {effective_mask[3:0], effective_mask[7:4]};  // 重排列
        end else if (pattern_sel_reg == 3'b110) begin
            // 处理6的情况 - 自定义模式
            effective_mask = mask_pattern_reg;
        end
    end
    
    // 优化输出逻辑，使用位布尔等式: A & ~B = A & (~B)
    always @(posedge clk or posedge reset) begin
        if (reset)
            masked_interrupt <= 8'h00;
        else
            masked_interrupt <= interrupt_reg & (~effective_mask);
    end
endmodule