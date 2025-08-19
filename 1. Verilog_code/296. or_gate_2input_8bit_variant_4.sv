//SystemVerilog
module or_gate_2input_8bit (
    input wire clk,        // 时钟输入
    input wire rst_n,      // 复位信号
    input wire [7:0] a,    // 输入向量a
    input wire [7:0] b,    // 输入向量b
    output reg [7:0] y     // 寄存器输出
);
    // 中间信号声明
    reg [7:0] a_reg, b_reg;
    reg [3:0] lower_result, upper_result;
    
    // 扁平化的流水线处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'h00;
            b_reg <= 8'h00;
            lower_result <= 4'h0;
            upper_result <= 4'h0;
            y <= 8'h00;
        end else if (rst_n) begin
            // 第一级流水线 - 输入寄存
            a_reg <= a;
            b_reg <= b;
            
            // 第二级流水线 - 分段计算OR操作
            lower_result <= a_reg[3:0] | b_reg[3:0];    // 低4位OR运算
            upper_result <= a_reg[7:4] | b_reg[7:4];    // 高4位OR运算
            
            // 第三级流水线 - 合并结果
            y <= {upper_result, lower_result};  // 合并高低位结果
        end
    end
    
endmodule