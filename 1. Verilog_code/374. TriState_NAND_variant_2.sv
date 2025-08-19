//SystemVerilog
module TriState_NAND(
    input wire clk,        // 时钟输入
    input wire rst_n,      // 复位信号
    input wire en,         // 使能信号
    input wire [3:0] a,    // 输入操作数a
    input wire [3:0] b,    // 输入操作数b
    output reg [3:0] y     // 输出结果
);
    // 优化流水线寄存器结构
    reg en_pipe [1:0];     // 使能信号流水线寄存器
    reg [3:0] a_pipe;      // a操作数流水线寄存器 
    reg [3:0] b_pipe;      // b操作数流水线寄存器
    reg [3:0] nand_result; // NAND操作结果

    // 第一级流水线 - 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_pipe[0] <= 1'b0;
            a_pipe <= 4'b0;
            b_pipe <= 4'b0;
        end else begin
            en_pipe[0] <= en;
            a_pipe <= a;
            b_pipe <= b;
        end
    end

    // 第二级流水线 - NAND运算和使能传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nand_result <= 4'b0;
            en_pipe[1] <= 1'b0;
        end else begin
            // 优化比较逻辑: 先计算a_pipe与b_pipe的位与，再取反
            nand_result <= ~(a_pipe & b_pipe);
            en_pipe[1] <= en_pipe[0];
        end
    end

    // 第三级流水线 - 三态输出控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 4'bz;
        end else begin
            // 使用条件运算符控制输出
            y <= en_pipe[1] ? nand_result : 4'bz;
        end
    end

endmodule