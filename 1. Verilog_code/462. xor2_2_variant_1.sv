//SystemVerilog
module xor2_2 (
    input  wire clk,      // 时钟输入以支持流水线结构
    input  wire rst_n,    // 复位信号以保证可靠初始化
    input  wire A, B,     // 输入数据信号
    output reg  Y         // 输出结果
);
    // 将组合逻辑切分为流水线阶段，提高时序性能
    
    // 阶段寄存器
    reg a_reg, b_reg;
    reg xor_result;
    
    // 统一的时序逻辑块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位状态
            a_reg <= 1'b0;
            b_reg <= 1'b0;
            xor_result <= 1'b0;
            Y <= 1'b0;
        end 
        else begin
            // 正常操作
            a_reg <= A;
            b_reg <= B;
            xor_result <= a_reg ^ b_reg;
            Y <= xor_result;
        end
    end

endmodule