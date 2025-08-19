//SystemVerilog
module xor2_14 (
    input  wire clk,    // 添加时钟输入以支持流水线结构
    input  wire rst_n,  // 添加复位信号以确保可靠初始化
    input  wire A,      // 第一个输入信号
    input  wire B,      // 第二个输入信号
    output reg  Y       // 异或结果输出
);
    // 内部信号声明 - 使数据流更清晰
    reg stage1_a;       // 输入A的寄存级
    reg stage1_b;       // 输入B的寄存级
    wire xor_result;    // 组合逻辑计算结果
    
    // 第一级流水线 - 寄存输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 1'b0;
            stage1_b <= 1'b0;
        end else begin
            stage1_a <= A;
            stage1_b <= B;
        end
    end
    
    // 组合逻辑计算 - 分离计算逻辑以降低路径复杂度
    assign xor_result = stage1_a ^ stage1_b;
    
    // 输出级 - 寄存结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= xor_result;
        end
    end
    
endmodule