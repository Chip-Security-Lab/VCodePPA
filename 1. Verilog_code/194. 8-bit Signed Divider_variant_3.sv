//SystemVerilog
module divider_signed_8bit (
    input wire clk,           // 添加时钟输入
    input wire rst_n,         // 添加复位输入
    input wire valid_in,      // 输入有效信号
    input wire [7:0] dividend,
    input wire [7:0] divisor,
    output reg valid_out,     // 输出有效信号
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    // 内部信号声明
    reg [7:0] dividend_abs, divisor_abs;
    reg [7:0] quotient_abs, remainder_abs;
    reg dividend_sign, divisor_sign, result_sign;
    
    // 流水线寄存器 - 第一级
    reg [7:0] dividend_reg, divisor_reg;
    reg valid_stage1;
    
    // 流水线寄存器 - 第二级
    reg [7:0] dividend_abs_reg, divisor_abs_reg;
    reg dividend_sign_reg, divisor_sign_reg;
    reg valid_stage2;
    
    // 流水线寄存器 - 第三级
    reg [7:0] quotient_abs_reg, remainder_abs_reg;
    reg result_sign_reg;
    reg valid_stage3;

    // 流水线阶段1: 输入寄存和信号准备
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dividend_reg <= 8'b0;
            divisor_reg <= 8'b0;
            valid_stage1 <= 1'b0;
        end else begin
            dividend_reg <= dividend;
            divisor_reg <= divisor;
            valid_stage1 <= valid_in;
        end
    end
    
    // 流水线阶段2: 符号处理和绝对值计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dividend_abs_reg <= 8'b0;
            divisor_abs_reg <= 8'b0;
            dividend_sign_reg <= 1'b0;
            divisor_sign_reg <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            // 提取符号信息
            dividend_sign_reg <= dividend_reg[7];
            divisor_sign_reg <= divisor_reg[7];
            
            // 计算绝对值
            dividend_abs_reg <= dividend_reg[7] ? (~dividend_reg + 1'b1) : dividend_reg;
            divisor_abs_reg <= divisor_reg[7] ? (~divisor_reg + 1'b1) : divisor_reg;
            
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 流水线阶段3: 无符号除法运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient_abs_reg <= 8'b0;
            remainder_abs_reg <= 8'b0;
            result_sign_reg <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            // 执行无符号除法
            quotient_abs_reg <= dividend_abs_reg / divisor_abs_reg;
            remainder_abs_reg <= dividend_abs_reg % divisor_abs_reg;
            
            // 确定结果符号
            result_sign_reg <= dividend_sign_reg ^ divisor_sign_reg;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 流水线阶段4: 符号恢复和输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient <= 8'b0;
            remainder <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            // 应用符号到结果
            quotient <= result_sign_reg ? (~quotient_abs_reg + 1'b1) : quotient_abs_reg;
            // 余数符号与被除数相同
            remainder <= dividend_sign_reg ? (~remainder_abs_reg + 1'b1) : remainder_abs_reg;
            valid_out <= valid_stage3;
        end
    end

endmodule