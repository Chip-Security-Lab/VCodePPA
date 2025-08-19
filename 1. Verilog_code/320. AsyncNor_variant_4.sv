//SystemVerilog
module AsyncNor(
    input clk,
    input rst,
    input a,
    input b,
    output reg y
);
    // Stage 1 - 输入寄存器
    reg a_stage1, b_stage1;
    reg valid_stage1;
    
    // Stage 2 - 计算NOR结果
    reg nor_result_stage2;
    reg valid_stage2;
    
    // 合并的流水线 - 包含所有时序逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 第一级流水线重置
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            
            // 第二级流水线重置
            nor_result_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            
            // 输出寄存器重置
            y <= 1'b0;
        end else begin
            // 第一级流水线 - 寄存输入值
            a_stage1 <= a;
            b_stage1 <= b;
            valid_stage1 <= 1'b1; // 假设输入总是有效
            
            // 第二级流水线 - 计算NOR结果
            nor_result_stage2 <= ~(a_stage1 | b_stage1);
            valid_stage2 <= valid_stage1;
            
            // 输出寄存器
            if (valid_stage2) begin
                y <= nor_result_stage2;
            end
        end
    end
    
endmodule