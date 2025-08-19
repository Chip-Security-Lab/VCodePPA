//SystemVerilog
//IEEE 1364-2005 Verilog
`timescale 1ns / 1ps

// 顶层模块 - 8位二进制除法器 (通过乘法倒数优化)
module divider_8bit (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [7:0] dividend,  // 被除数
    input wire [7:0] divisor,   // 除数
    output reg [7:0] quotient,  // 商
    output reg [7:0] remainder, // 余数
    output reg done             // 运算完成标志
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam FINISH = 2'b10;
    
    // 内部寄存器和信号
    reg [1:0] state, next_state;
    reg [7:0] divisor_reg;
    reg [7:0] dividend_reg;
    reg [15:0] reciprocal; // 除数的倒数近似值
    reg [15:0] mult_result; // 乘法结果
    reg [7:0] q_approx; // 近似商
    reg [7:0] r_temp; // 临时余数
    
    // 状态转换逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 下一状态逻辑
    always @(*) begin
        case (state)
            IDLE: next_state = start ? CALC : IDLE;
            CALC: next_state = FINISH;
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 牛顿-拉弗森迭代法计算倒数近似值
    function [15:0] calculate_reciprocal;
        input [7:0] div;
        reg [15:0] x0, x1;
        begin
            // 初始近似值 (基于查找表或简单估计)
            if (div[7])
                x0 = 16'h0100; // 如果最高位为1，设置初始值为2^8
            else if (div[6])
                x0 = 16'h0200; // 如果第二高位为1，设置初始值为2^9
            else
                x0 = 16'h0400; // 否则设置为2^10
            
            // 第一次牛顿迭代: x1 = x0 * (2 - div * x0)
            x1 = ((x0 * (16'h0200 - ((div * x0) >> 8))) >> 7);
            
            // 第二次牛顿迭代 (提高精度)
            calculate_reciprocal = ((x1 * (16'h0200 - ((div * x1) >> 8))) >> 7);
        end
    endfunction
    
    // 主运算逻辑 - 使用乘法倒数优化除法
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            divisor_reg <= 8'd0;
            dividend_reg <= 8'd0;
            reciprocal <= 16'd0;
            mult_result <= 16'd0;
            q_approx <= 8'd0;
            r_temp <= 8'd0;
            quotient <= 8'd0;
            remainder <= 8'd0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        // 特殊情况处理：除数为0
                        if (divisor == 8'd0) begin
                            quotient <= 8'hFF; // 设置为全1表示错误
                            remainder <= dividend;
                            done <= 1'b1;
                        end else begin
                            dividend_reg <= dividend;
                            divisor_reg <= divisor;
                            reciprocal <= calculate_reciprocal(divisor);
                            done <= 1'b0;
                        end
                    end
                end
                
                CALC: begin
                    // 使用乘法计算近似商: quotient ≈ dividend * (1/divisor)
                    mult_result <= (dividend_reg * reciprocal) >> 8;
                    
                    // 提取近似商和计算余数
                    q_approx <= (dividend_reg * reciprocal) >> 8;
                    r_temp <= dividend_reg - (((dividend_reg * reciprocal) >> 8) * divisor_reg);
                end
                
                FINISH: begin
                    // 修正近似商和余数
                    if (r_temp >= divisor_reg) begin
                        quotient <= q_approx + 8'd1;
                        remainder <= r_temp - divisor_reg;
                    end else if (r_temp[7]) begin  // 负数余数需要修正
                        quotient <= q_approx - 8'd1;
                        remainder <= r_temp + divisor_reg;
                    end else begin
                        quotient <= q_approx;
                        remainder <= r_temp;
                    end
                    done <= 1'b1;
                end
                
                default: begin
                    // 默认不做任何操作
                end
            endcase
        end
    end
endmodule