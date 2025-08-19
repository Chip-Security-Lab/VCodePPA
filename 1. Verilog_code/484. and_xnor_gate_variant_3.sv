//SystemVerilog
module and_xnor_gate (
    input wire clk,       // 时钟输入
    input wire rst_n,     // 复位信号，低电平有效
    input wire A, B, C,   // 数据输入信号
    output reg Y          // 处理后的输出
);
    // 内部信号定义 - 表示数据流的各个阶段
    reg stage1_A, stage1_B;      // 第一级流水线寄存器
    reg stage1_and_result;       // 第一级处理结果
    reg stage2_and_result, stage2_C; // 第二级流水线寄存器
    
    // 合并所有流水线逻辑到一个always块中
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有寄存器
            stage1_A <= 1'b0;
            stage1_B <= 1'b0;
            stage1_and_result <= 1'b0;
            stage2_and_result <= 1'b0;
            stage2_C <= 1'b0;
            Y <= 1'b0;
        end else begin
            // 第一级流水线 - 捕获输入
            stage1_A <= A;
            stage1_B <= B;
            
            // 第一级流水线 - 计算AND结果
            stage1_and_result <= stage1_A & stage1_B;
            
            // 第二级流水线 - 传递中间结果和捕获C输入
            stage2_and_result <= stage1_and_result;
            stage2_C <= C;
            
            // 最终输出级 - 执行XNOR操作并产生结果
            Y <= ~(stage2_and_result ^ stage2_C);
        end
    end
    
endmodule