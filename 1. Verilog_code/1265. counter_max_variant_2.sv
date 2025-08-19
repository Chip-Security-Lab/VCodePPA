//SystemVerilog
module counter_max #(parameter MAX=15) (
    input wire clk,
    input wire rst,
    input wire enable,  // 输入使能信号，控制计数器启动
    output reg [$clog2(MAX):0] cnt,
    output reg valid_out  // 输出有效信号
);

    // 流水线阶段1 - 决策和增量计算
    reg [$clog2(MAX):0] cnt_stage1;
    reg valid_stage1;
    reg at_max_stage1;
    reg [$clog2(MAX):0] next_cnt_stage1;
    
    // 流水线阶段2 - 更新和计数边界处理
    reg [$clog2(MAX):0] cnt_stage2;
    reg valid_stage2;
    reg [$clog2(MAX):0] final_cnt_stage2;
    
    // 流水线阶段3 - 输出寄存
    reg [$clog2(MAX):0] cnt_stage3;
    reg valid_stage3;
    
    // 阶段1：并行计算增量值和最大值检测
    always @(posedge clk) begin
        if (rst) begin
            cnt_stage1 <= 0;
            valid_stage1 <= 0;
            at_max_stage1 <= 0;
            next_cnt_stage1 <= 0;
        end
        else begin
            valid_stage1 <= enable;
            if (enable) begin
                cnt_stage1 <= cnt;
                at_max_stage1 <= (cnt == MAX);
                next_cnt_stage1 <= cnt + 1; // 预先计算下一个计数值
            end
        end
    end
    
    // 阶段2：更新逻辑 - 根据决策更新计数值
    always @(posedge clk) begin
        if (rst) begin
            cnt_stage2 <= 0;
            valid_stage2 <= 0;
            final_cnt_stage2 <= 0;
        end
        else begin
            valid_stage2 <= valid_stage1;
            cnt_stage2 <= cnt_stage1;
            if (valid_stage1) begin
                final_cnt_stage2 <= at_max_stage1 ? MAX : next_cnt_stage1;
            end
        end
    end
    
    // 阶段3: 额外的流水线阶段，增加吞吐量
    always @(posedge clk) begin
        if (rst) begin
            cnt_stage3 <= 0;
            valid_stage3 <= 0;
        end
        else begin
            valid_stage3 <= valid_stage2;
            if (valid_stage2) begin
                cnt_stage3 <= final_cnt_stage2;
            end
        end
    end
    
    // 输出阶段 - 更新最终输出
    always @(posedge clk) begin
        if (rst) begin
            cnt <= 0;
            valid_out <= 0;
        end
        else begin
            valid_out <= valid_stage3;
            if (valid_stage3) begin
                cnt <= cnt_stage3;
            end
        end
    end

endmodule