//SystemVerilog
//IEEE 1364-2005 Verilog标准
module xor2_5 (
    input wire clk,    // 添加时钟输入，用于流水线寄存器
    input wire rst_n,  // 添加复位信号
    input wire A, B, C, D,
    output wire Y
);
    // 实现4输入异或运算，使用流水线结构减少关键路径延迟
    
    // 第一级流水线 - 计算初始XOR结果
    reg stage1_xor_ab;
    reg stage1_xor_cd;
    
    // 第二级流水线 - 最终XOR结果
    reg stage2_result;
    
    // 数据流第一级 - 分别计算A^B和C^D
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_xor_ab <= 1'b0;
            stage1_xor_cd <= 1'b0;
        end else begin
            stage1_xor_ab <= A ^ B;
            stage1_xor_cd <= C ^ D;
        end
    end
    
    // 数据流第二级 - 合并中间结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 1'b0;
        end else begin
            stage2_result <= stage1_xor_ab ^ stage1_xor_cd;
        end
    end
    
    // 输出赋值
    assign Y = stage2_result;
    
endmodule