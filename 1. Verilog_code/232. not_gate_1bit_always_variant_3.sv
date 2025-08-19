//SystemVerilog
module not_gate_1bit_always (
    input wire clk,      // 添加时钟信号
    input wire rst_n,    // 添加复位信号
    input wire A,
    output reg Y_reg     // 重命名输出为更明确的名称
);
    // 内部信号
    reg A_captured;      // 捕获输入信号
    reg Y_computed;      // 计算结果的中间寄存器
    
    // 输入寄存捕获阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_captured <= 1'b0;
        end else begin
            A_captured <= A;
        end
    end
    
    // 计算阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y_computed <= 1'b1; // 复位值
        end else begin
            Y_computed <= ~A_captured;
        end
    end
    
    // 输出阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y_reg <= 1'b1; // 复位值
        end else begin
            Y_reg <= Y_computed;
        end
    end
    
endmodule