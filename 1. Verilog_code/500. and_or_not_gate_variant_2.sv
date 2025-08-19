//SystemVerilog
//IEEE 1364-2005
module and_or_not_gate (
    input wire clk,       // 系统时钟
    input wire rst_n,     // 异步复位，低电平有效
    input wire A, B, C,   // 输入A, B, C
    output reg Y          // 输出Y，改为寄存器输出
);
    // 中间信号声明
    reg stage1_and_result;  // A&B的结果
    reg stage1_not_result;  // ~C的结果
    reg stage2_or_result;   // 最终或运算结果

    // 第一级流水线 - 计算基本逻辑操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_and_result <= 1'b0;
            stage1_not_result <= 1'b0;
        end else begin
            stage1_and_result <= A & B;    // 与操作
            stage1_not_result <= ~C;       // 非操作
        end
    end

    // 第二级流水线 - 合并结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_or_result <= 1'b0;
        end else begin
            stage2_or_result <= stage1_and_result | stage1_not_result;  // 或操作
        end
    end

    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= stage2_or_result;
        end
    end

endmodule