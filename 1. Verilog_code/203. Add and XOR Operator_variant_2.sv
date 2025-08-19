//SystemVerilog
module add_xor_operator (
    input wire clk,         // 添加时钟输入
    input wire rst_n,       // 添加复位信号
    input wire [7:0] a,     // 输入数据a
    input wire [7:0] b,     // 输入数据b
    output reg [7:0] sum,   // 加法结果寄存器输出
    output reg [7:0] xor_result // 异或结果寄存器输出
);
    // 内部信号声明 - 用于流水线阶段
    reg [7:0] a_reg, b_reg;           // 第一级流水线寄存器
    reg [7:0] sum_comb, xor_comb;     // 组合逻辑计算结果
    
    // 第一级流水线 - 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'h0;
            b_reg <= 8'h0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // 组合逻辑计算 - 分割数据通路
    always @(*) begin
        // 加法操作 - 单独数据路径
        sum_comb = a_reg + b_reg;
        
        // 异或操作 - 并行数据路径
        xor_comb = a_reg ^ b_reg;
    end
    
    // 第二级流水线 - 输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 8'h0;
            xor_result <= 8'h0;
        end else begin
            sum <= sum_comb;
            xor_result <= xor_comb;
        end
    end

endmodule