//SystemVerilog
module fractional_n_div #(
    parameter INT_DIV = 4,
    parameter FRAC_DIV = 3,
    parameter FRAC_BITS = 4
) (
    input clk_src, reset_n,
    output reg clk_out
);
    reg [3:0] int_counter;
    reg [FRAC_BITS-1:0] frac_acc;
    reg frac_overflow_pipe;
    reg [3:0] int_target_pipe;
    reg [FRAC_BITS-1:0] frac_next_pipe;
    
    // 将组合逻辑计算拆分为流水线阶段
    reg [FRAC_BITS-1:0] frac_add_result;
    reg frac_overflow;
    reg [3:0] int_target;
    
    // 第一级流水线：计算下一个周期的小数累加值
    always @(posedge clk_src or negedge reset_n) begin
        if (!reset_n) begin
            frac_add_result <= 0;
            frac_overflow <= 0;
        end else begin
            frac_add_result <= frac_acc + FRAC_DIV;
            frac_overflow <= (frac_acc + FRAC_DIV) >= (1 << FRAC_BITS);
        end
    end
    
    // 第二级流水线：基于小数溢出确定整数计数目标值
    always @(posedge clk_src or negedge reset_n) begin
        if (!reset_n) begin
            int_target <= 0;
            frac_next_pipe <= 0;
            frac_overflow_pipe <= 0;
        end else begin
            frac_overflow_pipe <= frac_overflow;
            frac_next_pipe <= frac_add_result;
            int_target_pipe <= frac_overflow ? (INT_DIV - 1) : (INT_DIV - 2);
        end
    end
    
    // 主时序逻辑
    always @(posedge clk_src or negedge reset_n) begin
        if (!reset_n) begin
            int_counter <= 0;
            frac_acc <= 0;
            clk_out <= 0;
        end 
        else begin
            if (int_counter == int_target_pipe) begin
                int_counter <= 0;
                
                // 小数部分累加器更新
                if (frac_overflow_pipe)
                    frac_acc <= frac_next_pipe - (1 << FRAC_BITS);
                else
                    frac_acc <= frac_next_pipe;
                    
                // 时钟输出翻转
                clk_out <= ~clk_out;
            end 
            else begin
                int_counter <= int_counter + 1;
            end
        end
    end
endmodule