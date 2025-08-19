//SystemVerilog
module fuzzy_pattern_matcher #(
    parameter W = 8,               // 数据宽度
    parameter MAX_MISMATCHES = 2   // 允许的最大不匹配数
) (
    input wire clk,                // 时钟信号
    input wire rst_n,              // 复位信号（低电平有效）
    input wire [W-1:0] data,       // 输入数据
    input wire [W-1:0] pattern,    // 匹配模式
    output reg match               // 匹配结果输出
);

    // 第一级流水线：计算差异
    reg [W-1:0] diff_stage1;
    reg [W-1:0] data_stage1, pattern_stage1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_stage1 <= 0;
            data_stage1 <= 0;
            pattern_stage1 <= 0;
        end else begin
            data_stage1 <= data;
            pattern_stage1 <= pattern;
            diff_stage1 <= data ^ pattern;
        end
    end

    // 第二级流水线：使用查找表优化计数
    reg [3:0] count_stage2;
    reg [W-1:0] diff_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_stage2 <= 0;
            diff_stage2 <= 0;
        end else begin
            diff_stage2 <= diff_stage1;
            count_stage2 <= count_ones_optimized(diff_stage1);
        end
    end

    // 第三级流水线：比较和输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match <= 0;
        end else begin
            match <= (count_stage2 <= MAX_MISMATCHES);
        end
    end

    // 优化的计数函数 - 使用查找表方法
    function [3:0] count_ones_optimized;
        input [W-1:0] bits;
        reg [3:0] count;
        begin
            count = 0;
            // 使用4位查找表优化计数
            count = count + bits[0] + bits[1] + bits[2] + bits[3];
            count = count + bits[4] + bits[5] + bits[6] + bits[7];
            count_ones_optimized = count;
        end
    endfunction

endmodule