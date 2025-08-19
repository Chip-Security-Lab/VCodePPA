//SystemVerilog
module counter_max #(parameter MAX=15) (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    output reg  [$clog2(MAX):0] cnt
);

    // 优化阶段1:计算下一个值
    reg [$clog2(MAX):0] next_cnt_stage1;
    reg valid_stage1;
    
    // 优化阶段2:提前比较和选择路径
    reg is_max_reached;
    reg [$clog2(MAX):0] next_cnt_stage2;
    reg valid_stage2;

    // 常量比较阈值 - 提前计算常量表达式
    localparam MAX_VALUE = MAX;
    
    // 阶段1: 计算并并行比较
    always @(posedge clk) begin
        if (rst) begin
            next_cnt_stage1 <= 0;
            valid_stage1 <= 0;
            is_max_reached <= 0;
        end
        else if (enable) begin
            // 路径平衡：并行处理加法和比较操作
            next_cnt_stage1 <= cnt + 1'b1;
            // 将比较逻辑前移到第一阶段
            is_max_reached <= (cnt >= MAX_VALUE - 1);
            valid_stage1 <= 1'b1;
        end
        else begin
            valid_stage1 <= 1'b0;
        end
    end

    // 阶段2: 简化逻辑，利用预计算结果
    always @(posedge clk) begin
        if (rst) begin
            next_cnt_stage2 <= 0;
            valid_stage2 <= 0;
        end
        else if (valid_stage1) begin
            // 使用预计算的比较结果，减少逻辑深度
            next_cnt_stage2 <= is_max_reached ? MAX_VALUE : next_cnt_stage1;
            valid_stage2 <= 1'b1;
        end
        else begin
            valid_stage2 <= 1'b0;
        end
    end

    // 最终输出 - 简化条件逻辑
    always @(posedge clk) begin
        if (rst) begin
            cnt <= 0;
        end
        else if (valid_stage2) begin
            cnt <= next_cnt_stage2;
        end
    end

endmodule