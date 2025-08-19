//SystemVerilog
module fsm_clock_gate (
    input  wire clk_in,      // 系统时钟输入
    input  wire rst_n,       // 低电平有效复位信号
    input  wire start,       // 启动信号
    input  wire done,        // 完成信号
    output wire clk_out      // 门控时钟输出
);
    // 状态定义
    localparam STATE_IDLE   = 1'b0;
    localparam STATE_ACTIVE = 1'b1;
    
    // 流水线状态寄存器
    reg current_state_stage1, next_state_stage1;
    reg current_state_stage2, next_state_stage2;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    
    // 流水线数据寄存器
    reg start_stage1, done_stage1;
    
    // 时钟门控使能信号
    reg clk_enable_stage1, clk_enable_stage2;
    
    // 第一级流水线 - 输入寄存和状态检测
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            start_stage1 <= 1'b0;
            done_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            current_state_stage1 <= STATE_IDLE;
        end else begin
            start_stage1 <= start;
            done_stage1 <= done;
            valid_stage1 <= 1'b1;
            current_state_stage1 <= next_state_stage1;
        end
    end
    
    // 第一级流水线状态转换逻辑
    always @(*) begin
        if (current_state_stage1 == STATE_IDLE)
            next_state_stage1 = start_stage1 ? STATE_ACTIVE : STATE_IDLE;
        else if (current_state_stage1 == STATE_ACTIVE)
            next_state_stage1 = done_stage1 ? STATE_IDLE : STATE_ACTIVE;
        else
            next_state_stage1 = STATE_IDLE;
    end
    
    // 第一级流水线时钟使能逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            clk_enable_stage1 <= 1'b0;
        end else if (valid_stage1) begin
            clk_enable_stage1 <= (next_state_stage1 == STATE_ACTIVE);
        end
    end
    
    // 第二级流水线 - 状态更新和输出生成
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            current_state_stage2 <= STATE_IDLE;
            clk_enable_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            current_state_stage2 <= current_state_stage1;
            clk_enable_stage2 <= clk_enable_stage1;
        end
    end
    
    // 第二级流水线状态转换逻辑
    always @(*) begin
        if (current_state_stage2 == STATE_IDLE)
            next_state_stage2 = start ? STATE_ACTIVE : STATE_IDLE;
        else if (current_state_stage2 == STATE_ACTIVE)
            next_state_stage2 = done ? STATE_IDLE : STATE_ACTIVE;
        else
            next_state_stage2 = STATE_IDLE;
    end
    
    // 时钟门控输出 - 使用最终级的使能信号
    assign clk_out = clk_in & (valid_stage2 ? clk_enable_stage2 : 1'b0);
    
endmodule