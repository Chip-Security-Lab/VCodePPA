//SystemVerilog
module mode_selectable_comparator(
    input wire clk,                   // 添加时钟信号用于流水线
    input wire rst_n,                 // 添加复位信号
    input wire [15:0] input_a,
    input wire [15:0] input_b,
    input wire signed_mode,           // 0=unsigned, 1=signed comparison
    output reg is_equal,
    output reg is_greater,
    output reg is_less
);
    // Stage 1: 寄存器输入数据和控制信号 - 降低输入负载和提高时序性能
    reg [15:0] stage1_a, stage1_b;
    reg stage1_signed_mode;
    
    // Stage 2: 计算比较结果寄存器 - 将比较操作结果暂存
    reg stage2_unsigned_eq, stage2_unsigned_gt, stage2_unsigned_lt;
    reg stage2_signed_eq, stage2_signed_gt, stage2_signed_lt;
    reg stage2_signed_mode;
    
    // 流水线级 1 - 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 16'b0;
            stage1_b <= 16'b0;
            stage1_signed_mode <= 1'b0;
        end else begin
            stage1_a <= input_a;
            stage1_b <= input_b;
            stage1_signed_mode <= signed_mode;
        end
    end
    
    // 流水线级 2 - 并行计算所有比较结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有计算结果
            stage2_unsigned_eq <= 1'b0;
            stage2_unsigned_gt <= 1'b0;
            stage2_unsigned_lt <= 1'b0;
            stage2_signed_eq <= 1'b0;
            stage2_signed_gt <= 1'b0;
            stage2_signed_lt <= 1'b0;
            stage2_signed_mode <= 1'b0;
        end else begin
            // 无符号比较
            stage2_unsigned_eq <= (stage1_a == stage1_b);
            stage2_unsigned_gt <= (stage1_a > stage1_b);
            stage2_unsigned_lt <= (stage1_a < stage1_b);
            
            // 有符号比较
            stage2_signed_eq <= (stage1_a == stage1_b);
            stage2_signed_gt <= ($signed(stage1_a) > $signed(stage1_b));
            stage2_signed_lt <= ($signed(stage1_a) < $signed(stage1_b));
            
            // 传递模式信号到下一级
            stage2_signed_mode <= stage1_signed_mode;
        end
    end
    
    // 流水线级 3 - 输出多路复用器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_equal <= 1'b0;
            is_greater <= 1'b0;
            is_less <= 1'b0;
        end else begin
            // 根据模式选择合适的比较结果
            is_equal <= stage2_signed_mode ? stage2_signed_eq : stage2_unsigned_eq;
            is_greater <= stage2_signed_mode ? stage2_signed_gt : stage2_unsigned_gt;
            is_less <= stage2_signed_mode ? stage2_signed_lt : stage2_unsigned_lt;
        end
    end
endmodule