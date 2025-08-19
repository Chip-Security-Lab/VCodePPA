//SystemVerilog
module xor2_19 (
    input wire clk,
    input wire rst_n,
    input wire A, B,
    output reg Y
);
    // 优化的流水线寄存器 - 提前计算XOR结果
    reg stage1_result;
    
    // 流水线第一级 - 直接计算XOR结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_result <= 1'b0;
        end else begin
            stage1_result <= A ^ B; // 直接在第一级计算XOR结果
        end
    end
    
    // 流水线第二级 - 输出结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= stage1_result; // 仅传递结果，无需重新计算
        end
    end
    
endmodule