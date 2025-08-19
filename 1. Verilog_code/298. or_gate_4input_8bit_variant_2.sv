//SystemVerilog
module or_gate_4input_8bit (
    input wire clk,           // 添加时钟输入用于流水线寄存器
    input wire rst_n,         // 添加复位信号
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [7:0] c,
    input wire [7:0] d,
    output reg [7:0] y        // 改为寄存器输出
);
    // 第一级流水线 - 数据分组或运算
    reg [7:0] ab_or_r;        // 第一级流水线寄存器
    reg [7:0] cd_or_r;        // 第一级流水线寄存器
    
    // 第一级流水线逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ab_or_r <= 8'h0;
            cd_or_r <= 8'h0;
        end else begin
            ab_or_r <= a | b;  // a和b的或运算结果存入寄存器
            cd_or_r <= c | d;  // c和d的或运算结果存入寄存器
        end
    end
    
    // 第二级流水线 - 最终结果计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 8'h0;
        end else begin
            y <= ab_or_r | cd_or_r;  // 第一级结果的或运算输出
        end
    end
endmodule