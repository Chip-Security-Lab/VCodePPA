//SystemVerilog
module fractional_n_div #(
    parameter INT_DIV = 4,
    parameter FRAC_DIV = 3,
    parameter FRAC_BITS = 4
) (
    input clk_src, reset_n,
    output reg clk_out
);
    // 整数分频计数器
    reg [3:0] int_counter;
    // 小数累加器
    reg [FRAC_BITS-1:0] frac_acc;
    
    // 流水线阶段1: 小数累加和溢出检测
    reg [FRAC_BITS-1:0] frac_sum_stage1;
    reg frac_overflow_stage1;
    
    // 流水线阶段2: 目标计数计算
    reg frac_overflow_stage2;
    reg [3:0] target_count_stage2;
    reg [FRAC_BITS-1:0] next_frac_acc_stage2;
    
    // 流水线阶段3: 计数器控制
    reg [3:0] target_count_stage3;
    reg [FRAC_BITS-1:0] next_frac_acc_stage3;
    reg counter_reset_stage3;
    
    // 时序逻辑部分 - 流水线级1: 小数累加计算
    always @(posedge clk_src or negedge reset_n) begin
        if (!reset_n) begin
            frac_sum_stage1 <= 0;
            frac_overflow_stage1 <= 0;
        end else begin
            // 计算小数累加
            frac_sum_stage1 <= frac_acc + FRAC_DIV;
            // 计算小数溢出
            frac_overflow_stage1 <= (frac_acc + FRAC_DIV) >= (1 << FRAC_BITS);
        end
    end
    
    // 流水线级2: 目标计数和下一个小数累加值计算
    always @(posedge clk_src or negedge reset_n) begin
        if (!reset_n) begin
            frac_overflow_stage2 <= 0;
            target_count_stage2 <= 0;
            next_frac_acc_stage2 <= 0;
        end else begin
            frac_overflow_stage2 <= frac_overflow_stage1;
            
            // 计算目标计数值
            if (frac_overflow_stage1)
                target_count_stage2 <= INT_DIV - 1;
            else
                target_count_stage2 <= INT_DIV - 2;
                
            // 计算下一个小数累加值
            if (frac_overflow_stage1)
                next_frac_acc_stage2 <= frac_sum_stage1 - (1 << FRAC_BITS);
            else
                next_frac_acc_stage2 <= frac_sum_stage1;
        end
    end
    
    // 流水线级3: 计数器复位逻辑
    always @(posedge clk_src or negedge reset_n) begin
        if (!reset_n) begin
            target_count_stage3 <= 0;
            next_frac_acc_stage3 <= 0;
            counter_reset_stage3 <= 0;
        end else begin
            target_count_stage3 <= target_count_stage2;
            next_frac_acc_stage3 <= next_frac_acc_stage2;
            
            // 判断计数器是否复位
            counter_reset_stage3 <= (int_counter == target_count_stage2);
        end
    end
    
    // 流水线级4: 计数器和输出时钟更新
    always @(posedge clk_src or negedge reset_n) begin
        if (!reset_n) begin
            int_counter <= 0;
            frac_acc <= 0;
            clk_out <= 0;
        end else begin
            // 更新计数器和输出时钟
            if (counter_reset_stage3) begin
                int_counter <= 0;
                frac_acc <= next_frac_acc_stage3;
                clk_out <= ~clk_out;
            end else begin
                int_counter <= int_counter + 1;
            end
        end
    end
endmodule