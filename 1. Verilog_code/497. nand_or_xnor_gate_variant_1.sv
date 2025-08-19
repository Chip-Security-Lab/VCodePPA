//SystemVerilog
module nand_or_xnor_gate (
    input wire clk,         // 时钟输入
    input wire rst_n,       // 复位信号（低电平有效）
    input wire A, B, C,     // 输入A, B, C
    output reg Y            // 输出Y
);

    // 内部信号定义
    reg nand_result_r;      // 与非运算结果寄存器
    reg xnor_result_r;      // 同或运算结果寄存器
    reg stage1_valid_r;     // 第一级流水线有效标志
    
    // 第一级流水线 - 计算基本逻辑运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nand_result_r <= 1'b0;
            xnor_result_r <= 1'b0;
            stage1_valid_r <= 1'b0;
        end else begin
            nand_result_r <= ~(A & B);       // 与非运算
            xnor_result_r <= (C ~^ A);       // 同或运算
            stage1_valid_r <= 1'b1;          // 设置第一级有效
        end
    end
    
    // 第二级流水线 - 组合逻辑结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else if (stage1_valid_r) begin
            Y <= nand_result_r | xnor_result_r;  // 或运算
        end
    end

endmodule