//SystemVerilog
module Timer_WindowCompare (
    input clk, rst_n, en,
    input [7:0] low_th, high_th,
    output reg in_window
);
    // 流水线寄存器声明
    reg [7:0] timer;
    reg en_stage1;
    
    // 优化后的比较结果寄存器 - 向后移动到组合逻辑之前
    reg compare_low_result_pre, compare_high_result_pre;
    
    // 阶段1: 计时器递增和预先计算比较结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer <= 8'h00;
            en_stage1 <= 1'b0;
            compare_low_result_pre <= 1'b0;
            compare_high_result_pre <= 1'b0;
        end 
        else begin
            en_stage1 <= en;
            
            if (en) begin
                timer <= timer + 8'h01;
            end
            
            // 后向寄存器重定时：将比较操作的结果直接在第一级流水线寄存
            compare_low_result_pre <= (timer >= low_th);
            compare_high_result_pre <= (timer <= high_th);
        end
    end
    
    // 阶段2: 最终窗口比较结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_window <= 1'b0;
        end 
        else begin
            if (en_stage1) begin
                in_window <= compare_low_result_pre && compare_high_result_pre;
            end
        end
    end
endmodule