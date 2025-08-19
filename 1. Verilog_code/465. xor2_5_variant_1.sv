//SystemVerilog
module xor2_5 (
    input wire clk,     // 添加时钟信号以支持流水线
    input wire rst_n,   // 添加复位信号
    input wire A, B, C, D,
    output reg Y        // 改为寄存器输出以支持流水线
);
    // 第一级流水线 - 并行计算初始XOR结果
    reg stage1_xor_ab;
    reg stage1_xor_cd;
    
    // 第二级流水线 - 将两个XOR结果合并
    reg stage2_xor_result;
    
    // 第一级流水线逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_xor_ab <= 1'b0;
            stage1_xor_cd <= 1'b0;
        end else begin
            stage1_xor_ab <= A ^ B;  // 第一组XOR计算
            stage1_xor_cd <= C ^ D;  // 第二组XOR计算（并行）
        end
    end
    
    // 第二级流水线逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_xor_result <= 1'b0;
        end else begin
            stage2_xor_result <= stage1_xor_ab ^ stage1_xor_cd;  // 合并结果
        end
    end
    
    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= stage2_xor_result;  // 最终结果
        end
    end
endmodule