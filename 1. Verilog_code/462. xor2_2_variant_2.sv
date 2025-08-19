//SystemVerilog
module xor2_2 (
    input  wire clk,         // 时钟信号
    input  wire rst_n,       // 低电平有效的复位信号
    input  wire A,           // 输入端口A
    input  wire B,           // 输入端口B
    output reg  Y            // 注册输出端口Y
);
    // 内部流水线信号
    reg stage1_xor_result;
    
    // 第一级流水线 - 计算XOR结果并寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_xor_result <= 1'b0;
        end else begin
            stage1_xor_result <= A ^ B;
        end
    end
    
    // 第二级流水线 - 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= stage1_xor_result;
        end
    end
    
endmodule