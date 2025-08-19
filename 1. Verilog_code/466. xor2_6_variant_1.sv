//SystemVerilog
module xor2_6 (
    input  wire clk,     // 时钟输入
    input  wire rst_n,   // 复位信号，低电平有效
    input  wire A,       // 数据输入A
    input  wire B,       // 数据输入B
    output reg  Y        // 数据输出Y
);
    // 内部信号定义
    reg a_stage1;        // A信号流水线寄存器
    reg b_stage1;        // B信号流水线寄存器
    reg xor_result;      // XOR运算结果

    // 输入流水线阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
        end else begin
            a_stage1 <= A;
            b_stage1 <= B;
        end
    end
    
    // 计算流水线阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_result <= 1'b0;
        end else begin
            xor_result <= a_stage1 ^ b_stage1;
        end
    end
    
    // 输出流水线阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= xor_result;
        end
    end
    
endmodule