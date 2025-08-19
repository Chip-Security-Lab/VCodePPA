//SystemVerilog
module DiffSignalRecovery #(parameter THRESHOLD=100) (
    input clk,
    input diff_p, diff_n,
    output reg recovered
);
    // 寄存器化输入信号
    reg diff_p_reg, diff_n_reg;
    // 计算差值的寄存器
    reg signed [15:0] diff;
    // 阈值判断的中间结果
    reg threshold_result;
    
    // 将输入信号寄存器化，减少输入到第一级寄存器的延迟
    always @(posedge clk) begin
        diff_p_reg <= diff_p;
        diff_n_reg <= diff_n;
    end
    
    // 计算差值并进行阈值判断
    always @(posedge clk) begin
        diff <= diff_p_reg - diff_n_reg;
    end
    
    // 阈值判断逻辑，使用if-else结构替代条件运算符
    always @(posedge clk) begin
        if (diff > THRESHOLD) begin
            threshold_result <= 1'b1;
        end else if (diff < -THRESHOLD) begin
            threshold_result <= 1'b0;
        end else begin
            threshold_result <= recovered;
        end
    end
    
    // 输出寄存器
    always @(posedge clk) begin
        recovered <= threshold_result;
    end
endmodule