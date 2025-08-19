//SystemVerilog
module xor_or_nand_gate (
    input wire clk,       // 时钟输入
    input wire rst_n,     // 复位信号，低电平有效
    input wire A, B, C,   // 输入A, B, C
    output reg Y          // 输出Y，寄存器输出
);
    // 第一级流水线寄存器
    reg stage1_result1;   // A^B的结果寄存器
    reg stage1_result2;   // ~(C&A)的结果寄存器
    
    // 优化的组合逻辑计算 - 使用简化的布尔表达式
    // A^B = (A&~B)|(~A&B)
    wire stage1_logic1 = (A & ~B) | (~A & B);
    // ~(C&A) = ~C | ~A
    wire stage1_logic2 = ~C | ~A;
    
    // 流水线寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有寄存器
            stage1_result1 <= 1'b0;
            stage1_result2 <= 1'b0;
            Y <= 1'b0;
        end
        else begin
            // 第一级流水线寄存器
            stage1_result1 <= stage1_logic1;
            stage1_result2 <= stage1_logic2;
            
            // 第二级流水线寄存器 - 最终结果
            Y <= stage1_result1 | stage1_result2;
        end
    end
    
endmodule