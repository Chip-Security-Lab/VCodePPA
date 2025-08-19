//SystemVerilog
module and_xor_xnor_gate (
    input  wire clk,       // 时钟信号
    input  wire rst_n,     // 复位信号，低电平有效
    input  wire A, B, C,   // 输入A, B, C
    output reg  Y          // 输出Y
);
    // 优化的流水线结构
    // 阶段1: 计算基本逻辑运算
    reg stage1_ab;         // A&B运算的中间结果 
    reg stage1_ca;         // C~^A运算的中间结果
    
    // 阶段2: 进一步组合
    reg stage2_result;     // 最终的计算结果
    
    // 第一级流水线 - 计算基本逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_ab <= 1'b0;
            stage1_ca <= 1'b0;
        end else begin
            // 直接使用XNOR运算符，减少中间非门使用
            stage1_ab <= A & B;
            stage1_ca <= C ~^ A;
        end
    end
    
    // 第二级流水线 - 组合结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 1'b0;
        end else begin
            stage2_result <= stage1_ab ^ stage1_ca;
        end
    end
    
    // 输出级 - 注册最终结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= stage2_result;
        end
    end
    
endmodule