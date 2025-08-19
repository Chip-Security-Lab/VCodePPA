//SystemVerilog
//IEEE 1364-2005 Verilog
module xor_or_gate (
    input wire A, B, C,   // 控制输入A、数据输入B和C
    input wire clk,       // 时钟输入，用于流水线寄存器
    input wire rst_n,     // 低电平有效复位信号
    output reg Y          // 结果输出Y，改为寄存器输出
);
    // 数据流阶段声明 - 实现清晰的流水线结构
    reg stage1_xor_result_r;  // A^B的寄存器结果
    reg stage1_c_buffer_r;    // C的流水线缓冲

    // 第一流水线级 - 捕获输入并执行初始操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_xor_result_r <= 1'b0;
            stage1_c_buffer_r <= 1'b0;
        end else begin
            stage1_xor_result_r <= A ^ B;  // 计算XOR结果并寄存
            stage1_c_buffer_r <= C;        // 缓存C信号以匹配流水线延迟
        end
    end

    // 第二流水线级 - 最终结果合成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= stage1_xor_result_r | stage1_c_buffer_r;  // 最终OR运算
        end
    end

    // 实现了(A^B)|C的功能，但现在通过2级流水线结构实现
    // 数据流路径：
    // 第一级：计算A^B并缓存C
    // 第二级：合并第一级结果完成计算
endmodule