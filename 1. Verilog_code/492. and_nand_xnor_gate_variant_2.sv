//SystemVerilog
`timescale 1ns / 1ps

module and_nand_xnor_gate (
    input wire clk,          // 时钟信号
    input wire reset_n,      // 异步复位信号，低电平有效
    input wire A, B, C, D,   // 输入A, B, C, D
    output reg Y             // 输出Y，寄存器输出
);

    // 第一级流水线优化：减少中间寄存器数量，合并逻辑计算
    reg ab_and;              // A和B的与运算结果
    reg cd_nand;             // C和D的与非运算结果 
    reg a_reg;               // 保存输入A的寄存器
    
    // 第二级流水线：优化逻辑路径
    reg stage2_result;       // 第二级结果
    
    // 第一级流水线逻辑 - 优化逻辑门组合
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ab_and <= 1'b0;
            cd_nand <= 1'b1;  // 与非门的复位值应为1
            a_reg <= 1'b0;
        end else begin
            // 直接计算A&B，避免额外的与门
            ab_and <= A & B;
            
            // 优化与非门实现，使用德摩根定律: ~(C&D) = ~C | ~D
            cd_nand <= (~C) | (~D);
            
            a_reg <= A;
        end
    end

    // 第二级流水线逻辑 - 重组逻辑以减少关键路径
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            stage2_result <= 1'b0;
        end else begin
            // 优化逻辑表达式，减少门延迟
            stage2_result <= ab_and & cd_nand;
        end
    end

    // 第三级流水线逻辑 - 优化XNOR实现
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            Y <= 1'b0;
        end else begin
            // 优化XNOR实现: ~(a^b) = (a&b) | (~a&~b)
            Y <= (stage2_result & a_reg) | (~stage2_result & ~a_reg);
        end
    end

endmodule