//SystemVerilog
module and_or_gate (
    input wire clk,       // 时钟信号
    input wire rst_n,     // 复位信号，低电平有效
    input wire A, B, C,   // 输入信号
    output reg Y          // 输出信号
);

    // 内部信号定义，用于分割数据路径
    reg stage1_A, stage1_B, stage1_C;  // 第一级寄存器
    reg and_result;                     // AND逻辑结果寄存器
    
    // 第一级流水线：寄存输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A <= 1'b0;
            stage1_B <= 1'b0;
            stage1_C <= 1'b0;
        end else begin
            stage1_A <= A;
            stage1_B <= B;
            stage1_C <= C;
        end
    end
    
    // 第二级流水线：计算AND结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result <= 1'b0;
        end else begin
            and_result <= stage1_A & stage1_B;
        end
    end
    
    // 第三级流水线：实现最终的多路选择器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= stage1_C ? 1'b1 : and_result;
        end
    end

endmodule