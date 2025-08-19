//SystemVerilog
module Triple_XNOR(
    input wire a, b, c, d,
    input wire clk, rst_n,  // 添加时钟和复位信号用于流水线寄存器
    output reg y
);
    // 第一级流水线 - 输入信号寄存
    reg a_r, b_r, c_r, d_r;
    
    // 第二级流水线 - 第一级XOR结果
    reg ab_xor, cd_xor;
    
    // 信号声明 - 组合逻辑部分
    wire ab_xor_comb, cd_xor_comb;
    wire y_comb;
    
    // 数据路径 - 第一级XOR组合逻辑
    assign ab_xor_comb = a_r ^ b_r;
    assign cd_xor_comb = c_r ^ d_r;
    
    // 数据路径 - 最终XNOR组合逻辑
    assign y_comb = ~(ab_xor ^ cd_xor);
    
    // 流水线寄存器 - 输入段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_r <= 1'b0;
            b_r <= 1'b0;
            c_r <= 1'b0;
            d_r <= 1'b0;
        end else begin
            a_r <= a;
            b_r <= b;
            c_r <= c;
            d_r <= d;
        end
    end
    
    // 流水线寄存器 - 中间XOR结果段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ab_xor <= 1'b0;
            cd_xor <= 1'b0;
        end else begin
            ab_xor <= ab_xor_comb;
            cd_xor <= cd_xor_comb;
        end
    end
    
    // 流水线寄存器 - 输出段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;
        end else begin
            y <= y_comb;
        end
    end
    
endmodule