//SystemVerilog
module or_gate_2input_8bit (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    output reg [7:0] y
);
    // 减少为两级流水线，移除多余的中间寄存器级
    // 第一级直接执行OR操作并寄存结果
    reg [7:0] result_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 8'b0;
        end else begin
            result_reg <= a | b;  // 直接对输入执行OR操作
        end
    end
    
    // 输出级：将结果更新到输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 8'b0;
        end else begin
            y <= result_reg;
        end
    end
    
endmodule