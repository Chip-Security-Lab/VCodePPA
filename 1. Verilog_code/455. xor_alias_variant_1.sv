//SystemVerilog
// 顶层模块 - 带有优化的数据流结构
module xor_alias(
    input  wire clk,     // 添加时钟输入用于流水线
    input  wire rst_n,   // 添加复位信号
    input  wire in1,     // 第一输入
    input  wire in2,     // 第二输入
    output wire result   // 处理结果
);
    // 内部流水线寄存器
    reg stage1_in1_r, stage1_in2_r;  // 第一级流水线输入寄存器
    reg stage2_xor_r;                // 第二级流水线XOR结果寄存器
    
    // 第一级 - 输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_in1_r <= 1'b0;
            stage1_in2_r <= 1'b0;
        end else begin
            stage1_in1_r <= in1;
            stage1_in2_r <= in2;
        end
    end
    
    // 第二级 - XOR运算与寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_xor_r <= 1'b0;
        end else begin
            stage2_xor_r <= stage1_in1_r ^ stage1_in2_r;
        end
    end
    
    // 输出分配
    assign result = stage2_xor_r;
    
endmodule