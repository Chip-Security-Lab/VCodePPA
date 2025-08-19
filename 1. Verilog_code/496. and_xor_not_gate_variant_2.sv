//SystemVerilog
module and_xor_not_gate (
    input wire clk,     // 时钟信号
    input wire rst_n,   // 复位信号，低电平有效
    input wire A, B, C, // 输入A, B, C
    output reg Y        // 输出Y，注册类型
);
    // 第一级流水线 - 输入寄存器
    reg A_reg, B_reg, C_reg;
    
    // 第二级流水线 - 中间计算结果
    reg and_result;
    reg notC;
    reg notA, notB;
    
    // 第三级流水线 - 部分结果
    reg term1, term2, term3;
    
    // 输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg <= 1'b0;
            B_reg <= 1'b0;
            C_reg <= 1'b0;
        end else begin
            A_reg <= A;
            B_reg <= B;
            C_reg <= C;
        end
    end
    
    // 第二级计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result <= 1'b0;
            notC <= 1'b0;
            notA <= 1'b0;
            notB <= 1'b0;
        end else begin
            and_result <= A_reg & B_reg;
            notC <= ~C_reg;
            notA <= ~A_reg;
            notB <= ~B_reg;
        end
    end
    
    // 第三级计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            term1 <= 1'b0;
            term2 <= 1'b0;
            term3 <= 1'b0;
        end else begin
            term1 <= and_result & C_reg; // A & B & C
            term2 <= notA & notC;        // ~A & ~C
            term3 <= notB & notC;        // ~B & ~C
        end
    end
    
    // 最终输出计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= term1 | term2 | term3;  // (A & B & C) | (~A & ~C) | (~B & ~C)
        end
    end
    
endmodule