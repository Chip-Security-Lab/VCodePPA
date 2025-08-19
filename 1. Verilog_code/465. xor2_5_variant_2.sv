//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// 顶层模块：4输入异或流水线实现
///////////////////////////////////////////////////////////////////////////////
module xor2_5 (
    input wire clk,          // 时钟信号
    input wire rst_n,        // 复位信号
    input wire A, B, C, D,   // 4个输入信号
    output reg Y             // 流水线输出
);
    // 流水线寄存器定义
    reg stage1_a, stage1_b, stage1_c, stage1_d;    // 第一级寄存器
    reg stage2_ab_result, stage2_cd_result;        // 第二级寄存器
    
    // 内部连线
    wire xor_ab_result, xor_cd_result;
    wire xor_final_result;
    
    // 数据流水线 - 第一级：寄存输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 1'b0;
            stage1_b <= 1'b0;
            stage1_c <= 1'b0;
            stage1_d <= 1'b0;
        end else begin
            stage1_a <= A;
            stage1_b <= B;
            stage1_c <= C;
            stage1_d <= D;
        end
    end
    
    // 异或逻辑计算
    assign xor_ab_result = stage1_a ^ stage1_b;
    assign xor_cd_result = stage1_c ^ stage1_d;
    
    // 数据流水线 - 第二级：寄存中间结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_ab_result <= 1'b0;
            stage2_cd_result <= 1'b0;
        end else begin
            stage2_ab_result <= xor_ab_result;
            stage2_cd_result <= xor_cd_result;
        end
    end
    
    // 最终异或结果计算
    assign xor_final_result = stage2_ab_result ^ stage2_cd_result;
    
    // 数据流水线 - 第三级：寄存输出结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= xor_final_result;
        end
    end
    
endmodule