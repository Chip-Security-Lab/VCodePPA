//SystemVerilog
module add_xor_operator (
    input wire clk,                // 添加时钟输入
    input wire rst_n,              // 添加复位信号
    input wire [7:0] a,
    input wire [7:0] b,
    input wire enable,             // 添加使能信号
    output reg [7:0] sum,
    output reg [7:0] xor_result
);
    // 内部流水线寄存器
    reg [7:0] a_reg, b_reg;
    reg [7:0] sum_comb, xor_comb;
    
    // 第一级：输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
        end else if (enable) begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // 第二级：计算组合逻辑
    always @(*) begin
        sum_comb = a_reg + b_reg;    // 加法运算
        xor_comb = a_reg ^ b_reg;    // 异或运算
    end
    
    // 第三级：输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 8'b0;
            xor_result <= 8'b0;
        end else if (enable) begin
            sum <= sum_comb;
            xor_result <= xor_comb;
        end
    end
endmodule