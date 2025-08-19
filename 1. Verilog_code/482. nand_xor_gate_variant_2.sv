//SystemVerilog
module nand_xor_gate (
    input  wire clk,      // 时钟信号
    input  wire rst_n,    // 复位信号，低电平有效
    input  wire A, B, C,  // 输入A, B, C
    output reg  Y         // 输出Y
);

    // 内部信号定义 - 分割数据流路径
    reg nand_result_stage1;  // 第一级 NAND 计算结果
    reg c_delayed_stage1;    // 第一级 C 输入延迟匹配

    // 第一级管道 - NAND 运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nand_result_stage1 <= 1'b1;  // NAND的复位值
            c_delayed_stage1 <= 1'b0;    // C信号的复位值
        end else begin
            nand_result_stage1 <= ~(A & B);  // NAND运算，使用德摩根定律
            c_delayed_stage1 <= C;           // 延迟C以匹配管道
        end
    end

    // 第二级管道 - XOR运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;  // 输出的复位值
        end else begin
            Y <= nand_result_stage1 ^ c_delayed_stage1;  // 异或运算
        end
    end

endmodule