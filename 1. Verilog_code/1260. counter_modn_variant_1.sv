//SystemVerilog
module counter_modn #(parameter N=10) (
    input wire clk,
    input wire rst,
    output reg [$clog2(N)-1:0] cnt
);

    // 内部信号定义 - 流水线阶段
    reg [$clog2(N)-1:0] cnt_stage1;          // 第一级流水线寄存器
    reg compare_result_stage1;               // 比较结果的第一级流水线寄存器
    reg valid_stage1;                        // 数据有效信号
    
    // 第一级流水线 - 计算和比较
    always @(posedge clk) begin
        if (rst) begin
            cnt_stage1 <= 0;
            compare_result_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else begin
            valid_stage1 <= 1;
            cnt_stage1 <= cnt;
            compare_result_stage1 <= (cnt == N-1);
        end
    end
    
    // 第二级流水线 - 更新计数器
    always @(posedge clk) begin
        if (rst) begin
            cnt <= 0;
        end
        else if (valid_stage1) begin
            if (compare_result_stage1) begin
                cnt <= 0;
            end
            else begin
                cnt <= cnt_stage1 + 1;
            end
        end
    end

endmodule