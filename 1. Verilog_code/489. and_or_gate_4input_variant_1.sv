//SystemVerilog
///////////////////////////////////////////////////////////
// Module: and_or_gate_4input
// Description: 四输入与或门的流水线实现
// Implements: Y = (A & B) | (C & D)
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////

module and_or_gate_4input (
    input wire clk,        // 时钟信号
    input wire rst_n,      // 低电平有效复位
    input wire A, B, C, D, // 四个输入
    output reg Y           // 注册后的输出Y
);

    // 第一级流水线 - 计算与操作
    reg and_result_AB_pipe1;
    reg and_result_CD_pipe1;
    
    // 第二级流水线 - 计算或操作和最终结果
    reg or_result_pipe2;
    
    // 中间信号声明
    wire and_result_AB;
    wire and_result_CD;
    wire or_result;
    
    // 第一阶段 - 并行计算与操作
    assign and_result_AB = A & B;
    assign and_result_CD = C & D;
    
    // 第二阶段 - 计算或操作
    assign or_result = and_result_AB_pipe1 | and_result_CD_pipe1;
    
    // 流水线寄存器更新 - 第一级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result_AB_pipe1 <= 1'b0;
            and_result_CD_pipe1 <= 1'b0;
        end else begin
            and_result_AB_pipe1 <= and_result_AB;
            and_result_CD_pipe1 <= and_result_CD;
        end
    end
    
    // 流水线寄存器更新 - 第二级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= or_result;
        end
    end
    
endmodule