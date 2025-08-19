//SystemVerilog
module or_gate_2input_8bit_generate (
    input wire clk,           // 添加时钟信号
    input wire rst_n,         // 添加复位信号
    input wire [7:0] a,
    input wire [7:0] b,
    input wire en,            // 添加使能信号
    output reg [7:0] y        // 改为寄存器输出
);
    // 内部信号声明 - 流水线寄存器
    reg [7:0] a_reg, b_reg;   // 输入寄存器级
    reg [7:0] or_result;      // 组合逻辑结果寄存器

    // 输入寄存器级 - 分割输入路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'h0;
            b_reg <= 8'h0;
        end else if (en) begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // 组合逻辑计算 - 维持原有功能
    always @(*) begin
        or_result = a_reg | b_reg;
    end

    // 输出寄存器级 - 分割输出路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 8'h0;
        end else if (en) begin
            y <= or_result;
        end
    end
endmodule