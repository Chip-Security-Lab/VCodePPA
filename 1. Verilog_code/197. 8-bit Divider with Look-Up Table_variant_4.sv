//SystemVerilog
module divider_lut_8bit (
    input wire clk,
    input wire rst_n,
    input wire [7:0] dividend,
    input wire [7:0] divisor,
    input wire start,
    output reg [7:0] quotient,
    output reg [7:0] remainder,
    output reg valid
);

    // 流水线阶段寄存器
    reg [7:0] dividend_r;
    reg [7:0] divisor_r;
    reg [7:0] lut_quotient;
    reg [15:0] mult_result; // 合并高低部分以减少寄存器数量
    reg start_r, start_r2;
    
    // LUT存储
    reg [7:0] div_lut [0:255];
    
    // 初始化查找表
    initial begin
        // 初始化LUT with precomputed values
        // 这部分保持不变
    end
    
    // 第一级流水线：输入寄存和LUT查找
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dividend_r <= 8'b0;
            divisor_r <= 8'b0;
            lut_quotient <= 8'b0;
            start_r <= 1'b0;
        end else begin
            dividend_r <= dividend;
            divisor_r <= divisor;
            lut_quotient <= div_lut[dividend];
            start_r <= start;
        end
    end
    
    // 第二级流水线：乘法计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_result <= 16'b0; // 初始化为0
            start_r2 <= 1'b0;
        end else begin
            // 直接计算乘法结果，减少寄存器数量
            mult_result <= lut_quotient * divisor_r;
            start_r2 <= start_r;
        end
    end
    
    // 第三级流水线：计算余数并输出结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient <= 8'b0;
            remainder <= 8'b0;
            valid <= 1'b0;
        end else begin
            quotient <= lut_quotient;
            remainder <= dividend_r - mult_result[7:0]; // 直接使用乘法结果
            valid <= start_r2;
        end
    end

endmodule