//SystemVerilog
// SystemVerilog
module xor2_13 (
    input wire clk,     // 时钟输入，用于流水线操作
    input wire rst_n,   // 低电平有效的异步复位信号
    input wire A, B,    // 输入信号
    output reg Y        // 输出信号
);
    // 内部信号定义 - 优化后的流水线阶段寄存器
    reg [1:0] stage1_data;  // 第一级流水线合并的A和B信号
    reg stage2_result;      // 第二级流水线结果寄存器

    // 第一级流水线 - 合并A和B信号寄存，减少always块数量
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 2'b00;
        end else begin
            stage1_data <= {A, B};
        end
    end

    // 第二级流水线 - 异或运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 1'b0;
        end else begin
            // 从合并的寄存器中提取信号并执行异或操作
            stage2_result <= stage1_data[1] ^ stage1_data[0];
        end
    end

    // 输出级 - 最终结果传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= stage2_result;
        end
    end

endmodule