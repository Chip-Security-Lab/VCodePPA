//SystemVerilog
module XNOR_Basic (
    input  wire clk,    // 时钟信号
    input  wire rst_n,  // 复位信号，低有效
    input  wire a,      // 输入信号a
    input  wire b,      // 输入信号b
    output reg  y       // 输出信号y
);

    // 内部信号声明 - 优化流水线结构
    reg stage1_a, stage1_b;  // 第一级流水线寄存器
    reg stage2_xnor_result;  // 第二级流水线寄存器 - 直接存储XNOR结果
    
    // 第一级流水线 - 输入缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 1'b0;
            stage1_b <= 1'b0;
        end else begin
            stage1_a <= a;
            stage1_b <= b;
        end
    end
    
    // 第二级流水线 - 直接计算XNOR结果
    // 将 (a&b)|((~a)&(~b)) 简化为 ~(a^b)，即XNOR
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_xnor_result <= 1'b0;
        end else begin
            stage2_xnor_result <= ~(stage1_a ^ stage1_b);  // 直接使用XNOR逻辑简化电路
        end
    end
    
    // 输出级 - 传递结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;
        end else begin
            y <= stage2_xnor_result;  // 直接传递XNOR结果
        end
    end

endmodule