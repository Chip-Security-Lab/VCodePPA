//SystemVerilog
module counter_max #(parameter MAX=15) (
    input wire clk,
    input wire rst,
    input wire en,
    output reg [$clog2(MAX):0] cnt_out
);
    // 主要数据通路信号定义
    reg [$clog2(MAX):0] cnt_current;
    
    // 流水线控制信号
    reg [1:0] valid_pipeline;  // 2位有效信号流水线寄存器
    
    // 流水线级1信号 - 比较阶段
    reg [$clog2(MAX):0] cnt_pipe1;
    reg compare_result_pipe1;
    
    // 流水线级2信号 - 计算阶段
    reg [$clog2(MAX):0] cnt_pipe2;
    reg compare_result_pipe2;
    reg [$clog2(MAX):0] next_cnt;
    
    // 流水线级1: 计数值采样和比较 
    always @(posedge clk) begin
        if (rst) begin
            cnt_pipe1 <= 0;
            compare_result_pipe1 <= 0;
            valid_pipeline[0] <= 0;
        end
        else begin
            cnt_pipe1 <= cnt_current;
            compare_result_pipe1 <= (cnt_current == MAX);
            valid_pipeline[0] <= en;
        end
    end
    
    // 流水线级2: 计算下一个计数值
    always @(posedge clk) begin
        if (rst) begin
            cnt_pipe2 <= 0;
            compare_result_pipe2 <= 0;
            valid_pipeline[1] <= 0;
            next_cnt <= 0;
        end
        else begin
            cnt_pipe2 <= cnt_pipe1;
            compare_result_pipe2 <= compare_result_pipe1;
            valid_pipeline[1] <= valid_pipeline[0];
            
            // 提前计算下一个计数值，降低逻辑深度
            next_cnt <= compare_result_pipe1 ? 0 : cnt_pipe1 + 1;
        end
    end
    
    // 输出阶段: 计数器更新逻辑
    always @(posedge clk) begin
        if (rst) begin
            cnt_current <= 0;
            cnt_out <= 0;
        end
        else if (valid_pipeline[1]) begin
            cnt_current <= compare_result_pipe2 ? 0 : next_cnt;
            cnt_out <= compare_result_pipe2 ? 0 : next_cnt;
        end
        else begin
            // 保持当前值
            cnt_current <= cnt_current;
            cnt_out <= cnt_out;
        end
    end
endmodule