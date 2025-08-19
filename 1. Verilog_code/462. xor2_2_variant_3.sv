//SystemVerilog
module xor2_2 (
    input wire clk,     // 时钟输入用于流水线结构
    input wire rst_n,   // 低电平有效复位信号
    input wire A, B,    // 输入信号
    output reg Y        // 输出信号
);
    // 定义流水线各级寄存器
    reg stage1_a, stage1_b;      // 第一级流水线输入寄存器
    reg stage2_result;           // 第二级流水线结果寄存器
    
    // 流水线第一级：捕获输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 1'b0;
            stage1_b <= 1'b0;
        end else begin
            stage1_a <= A;
            stage1_b <= B;
        end
    end
    
    // 流水线第二级：执行XOR逻辑运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 1'b0;
        end else begin
            stage2_result <= stage1_a ^ stage1_b; // 使用XOR运算符
        end
    end
    
    // 流水线第三级：输出结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= stage2_result;
        end
    end
    
endmodule