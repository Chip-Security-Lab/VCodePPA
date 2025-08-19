//SystemVerilog
`timescale 1ns / 1ps

module and_not_or_gate (
    input  wire clk,       // 时钟信号
    input  wire rst_n,     // 复位信号 (低电平有效)
    input  wire A, B, C,   // 输入信号
    output reg  Y          // 输出信号
);
    // IEEE 1364-2005 Verilog标准

    // 优化后的流水线阶段，减少冗余寄存器
    reg stage1_result;
    reg stage2_result;
    reg stage3_result;
    
    // 阶段1：捕获与布尔优化
    // 根据布尔代数，(A & B & ~C | A) 可简化为 (A & ~C | A)，即 A | (A & ~C)，进一步简化为 A
    // 但为保持数据流，使用优化的布尔运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_result <= 1'b0;
        end else begin
            // 使用 A 作为主要信号，减少后续阶段的寄存器需求
            stage1_result <= A;
        end
    end
    
    // 阶段2：继续计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 1'b0;
        end else begin
            // 由于 (A & B) & ~C | A 简化为 A，但为展示流水线
            // 我们保持相同延迟但减少资源使用
            stage2_result <= stage1_result;
        end
    end
    
    // 阶段3：完成计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_result <= 1'b0;
        end else begin
            stage3_result <= stage2_result;
        end
    end
    
    // 最终输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            // 优化后的逻辑：由于 (A & B) & ~C | A 简化为 A
            Y <= stage3_result;
        end
    end
    
endmodule