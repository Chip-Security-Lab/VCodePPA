//SystemVerilog
module and_xor_not_gate (
    input wire clk,        // 时钟输入
    input wire rst_n,      // 异步复位，低电平有效
    input wire A,          // 数据输入A
    input wire B,          // 数据输入B
    input wire C,          // 数据输入C
    output reg Y           // 处理后的输出结果
);

    // 流水线寄存器，用于分段处理
    reg stage1_A, stage1_B;    // 第一级寄存器，存储输入A和B
    reg stage1_C;              // 第一级寄存器，存储输入C
    reg stage2_and_result;     // 第二级寄存器，存储与操作结果
    reg stage2_not_C;          // 第二级寄存器，存储C的取反结果

    // 统一使用扁平化的if-else结构处理所有寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位状态处理 - 所有寄存器清零
            stage1_A <= 1'b0;
            stage1_B <= 1'b0;
            stage1_C <= 1'b0;
            stage2_and_result <= 1'b0;
            stage2_not_C <= 1'b0;
            Y <= 1'b0;
        end
        else begin
            // 第一级：捕获输入
            stage1_A <= A;
            stage1_B <= B;
            stage1_C <= C;
            
            // 第二级：计算基本逻辑操作
            stage2_and_result <= stage1_A & stage1_B;  // 与操作
            stage2_not_C <= ~stage1_C;                 // 非操作
            
            // 第三级：计算最终异或结果并输出
            Y <= stage2_and_result ^ stage2_not_C;     // 异或操作
        end
    end

endmodule