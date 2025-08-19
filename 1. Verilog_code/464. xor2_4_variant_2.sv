//SystemVerilog
module xor2_4 (
    input wire clk,     // 添加时钟信号用于流水线寄存器
    input wire rst_n,   // 添加复位信号以提高可靠性
    input wire A, B,    // 输入信号
    output reg Y        // 输出信号
);
    // 内部流水线寄存器信号
    reg stage1_a, stage1_b;  // 第一级流水线寄存器
    reg stage2_result;       // 第二级流水线寄存器
    
    // 第一级：输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 1'b0;
            stage1_b <= 1'b0;
        end else begin
            stage1_a <= A;
            stage1_b <= B;
        end
    end
    
    // 第二级：计算XOR结果并寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 1'b0;
        end else begin
            stage2_result <= stage1_a ^ stage1_b;
        end
    end
    
    // 输出级：驱动输出信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= stage2_result;
        end
    end
    
endmodule