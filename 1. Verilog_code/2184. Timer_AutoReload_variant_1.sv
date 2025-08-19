//SystemVerilog
module Timer_AutoReload #(parameter VAL=255) (
    input clk, en, rst,
    output reg alarm
);
    // 时钟缓冲树，用于减少clk的扇出负载
    reg clk_buf1, clk_buf2, clk_buf3;
    
    // 时钟缓冲寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_buf1 <= 1'b0;
            clk_buf2 <= 1'b0;
            clk_buf3 <= 1'b0;
        end else begin
            clk_buf1 <= ~clk_buf1;
            clk_buf2 <= ~clk_buf2;
            clk_buf3 <= ~clk_buf3;
        end
    end

    // Pipeline registers
    reg [7:0] cnt_stage1;
    reg [7:0] cnt_stage2;
    reg is_zero_stage1;
    reg is_zero_stage2;
    reg alarm_stage1;
    
    // 查找表辅助减法器实现
    reg [7:0] lut_sub [0:255]; // 查找表定义
    integer i;
    
    // 查找表初始化
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            lut_sub[i] = (i == 0) ? VAL : (i - 1); // 如果为0则加载VAL，否则减1
        end
    end
    
    // Stage 1: Compare counter with zero and calculate if it's zero
    // 使用缓冲时钟clk_buf1
    always @(posedge clk_buf1 or posedge rst) begin
        if (rst) begin
            cnt_stage1 <= VAL;
            is_zero_stage1 <= 0;
        end else if (en) begin
            cnt_stage1 <= cnt_stage2;
            is_zero_stage1 <= (cnt_stage2 == 0);
        end
    end
    
    // Stage 2: Update counter value based on zero condition using LUT
    // 使用缓冲时钟clk_buf2
    always @(posedge clk_buf2 or posedge rst) begin
        if (rst) begin
            cnt_stage2 <= VAL;
            is_zero_stage2 <= 0;
        end else if (en) begin
            is_zero_stage2 <= is_zero_stage1;
            cnt_stage2 <= is_zero_stage1 ? VAL : lut_sub[cnt_stage1]; // 使用查找表替代减法器
        end
    end
    
    // Stage 3: Generate alarm signal
    // 使用缓冲时钟clk_buf3
    always @(posedge clk_buf3 or posedge rst) begin
        if (rst) begin
            alarm_stage1 <= 0;
            alarm <= 0;
        end else if (en) begin
            alarm_stage1 <= is_zero_stage2;
            alarm <= alarm_stage1;
        end
    end
endmodule