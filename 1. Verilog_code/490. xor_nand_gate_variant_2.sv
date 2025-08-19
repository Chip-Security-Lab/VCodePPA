//SystemVerilog
module xor_nand_gate (
    input wire A, B, C,    // 输入A, B, C
    input wire clk,        // 时钟信号
    input wire rst_n,      // 低电平有效复位信号
    output reg Y           // 输出Y
);
    // 第一级流水线 - 中间信号计算
    reg stage1_a_not_b;    // A & ~B 信号
    reg stage1_a_not_c;    // A & ~C 信号
    reg stage1_not_a_b;    // ~A & B 信号
    
    // 第二级流水线 - 组合结果
    reg stage2_term1;      // A & ~B & ~C
    reg stage2_term2;      // ~A & B
    
    // 第一级流水线 - 计算基础逻辑项
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a_not_b <= 1'b0;
            stage1_a_not_c <= 1'b0;
            stage1_not_a_b <= 1'b0;
        end else begin
            stage1_a_not_b <= A & ~B;
            stage1_a_not_c <= A & ~C;
            stage1_not_a_b <= ~A & B;
        end
    end
    
    // 第二级流水线 - 组合中间结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_term1 <= 1'b0;
            stage2_term2 <= 1'b0;
        end else begin
            stage2_term1 <= stage1_a_not_b & stage1_a_not_c;
            stage2_term2 <= stage1_not_a_b;
        end
    end
    
    // 第三级流水线 - 生成最终输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= stage2_term1 | stage2_term2;
        end
    end
    
endmodule