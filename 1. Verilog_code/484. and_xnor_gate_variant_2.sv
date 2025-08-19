//SystemVerilog
`timescale 1ns / 1ps

module and_xnor_gate (
    input wire clk,       // 时钟信号
    input wire rst_n,     // 复位信号，低电平有效
    input wire A, B, C,   // 输入A, B, C
    output reg Y          // 输出Y
);

    // 直接缓存输入信号
    reg A_reg, B_reg, C_reg;
    
    // 输入寄存器阶段 - 将寄存器移向输入端
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg <= 1'b0;
            B_reg <= 1'b0;
            C_reg <= 1'b0;
        end else begin
            A_reg <= A;
            B_reg <= B;
            C_reg <= C;
        end
    end
    
    // 组合逻辑 + 输出寄存器阶段 - 将计算直接完成
    wire and_result;
    wire xnor_result;
    
    assign and_result = A_reg & B_reg;
    assign xnor_result = ~(and_result ^ C_reg);
    
    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= xnor_result;
        end
    end

endmodule