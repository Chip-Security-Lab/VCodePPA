//SystemVerilog
module or_gate_3input_4bit (
    input wire clk,
    input wire rst_n,
    input wire [3:0] a,
    input wire [3:0] b,
    input wire [3:0] c,
    output reg [3:0] y
);
    // 输入寄存器
    reg [3:0] a_reg, b_reg, c_reg;
    
    // 中间结果寄存器
    reg [3:0] a_c_or_reg, b_c_or_reg;
    
    // 第一级流水线 - 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0;
            b_reg <= 4'b0;
            c_reg <= 4'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            c_reg <= c;
        end
    end
    
    // 第二级流水线 - 并行计算两个或运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_c_or_reg <= 4'b0;
            b_c_or_reg <= 4'b0;
        end else begin
            a_c_or_reg <= a_reg | c_reg;
            b_c_or_reg <= b_reg | c_reg;
        end
    end
    
    // 第三级流水线 - 合并结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 4'b0;
        end else begin
            y <= a_c_or_reg | b_c_or_reg;
        end
    end
    
endmodule