//SystemVerilog
//IEEE 1364-2005
`timescale 1ns/1ps

module Divider_8bit (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [7:0] dividend,  // 被除数
    input wire [7:0] divisor,   // 除数
    output reg [7:0] quotient,  // 商
    output reg [7:0] remainder, // 余数
    output reg done             // 完成标志
);

    // 状态定义
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [7:0] dividend_reg;    // 存储被除数的寄存器
    reg [7:0] divisor_reg;
    reg [7:0] x_curr;
    reg [3:0] iter_count;
    
    // 临时变量用于牛顿迭代
    reg [15:0] mult_result1;   // 将组合逻辑转换为寄存器
    reg [7:0] two_minus_bx;    // 将组合逻辑转换为寄存器
    reg [15:0] mult_result2;   // 将组合逻辑转换为寄存器
    
    // 前向寄存器移动的中间信号
    wire [15:0] mult_result1_comb;
    wire [7:0] two_minus_bx_comb;
    wire [15:0] mult_result2_comb;
    
    // 状态转换逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 状态机逻辑
    always @(*) begin
        case (state)
            IDLE: next_state = start ? CALC : IDLE;
            CALC: next_state = (iter_count == 4'd4) ? DONE : CALC; // 迭代次数调整为4
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 组合逻辑计算
    assign mult_result1_comb = divisor_reg * x_curr;
    assign two_minus_bx_comb = 8'h02 - mult_result1_comb[7:0];
    assign mult_result2_comb = x_curr * two_minus_bx_comb;
    
    // 计算逻辑 - 重新定时，将寄存器向前推移
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            divisor_reg <= 8'h0;
            dividend_reg <= 8'h0;
            x_curr <= 8'h0;
            iter_count <= 4'h0;
            mult_result1 <= 16'h0;
            two_minus_bx <= 8'h0;
            mult_result2 <= 16'h0;
            quotient <= 8'h0;
            remainder <= 8'h0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        divisor_reg <= divisor;
                        dividend_reg <= dividend;
                        // 初始近似值 - 使用简单的初值
                        x_curr <= 8'h01;
                        iter_count <= 4'h0;
                        done <= 1'b0;
                    end
                end
                
                CALC: begin
                    // 存储组合逻辑结果到寄存器，实现前向重定时
                    mult_result1 <= mult_result1_comb;
                    two_minus_bx <= two_minus_bx_comb;
                    mult_result2 <= mult_result2_comb;
                    
                    // 在下一个周期使用已寄存的计算结果
                    x_curr <= mult_result2[7:0];
                    iter_count <= iter_count + 4'h1;
                end
                
                DONE: begin
                    // 计算最终结果
                    quotient <= (dividend_reg * x_curr) >> 8;
                    remainder <= dividend_reg - ((dividend_reg * x_curr) >> 8) * divisor_reg;
                    done <= 1'b1;
                end
            endcase
        end
    end

endmodule

module Delay_NAND(
    input x, y,
    output reg z  // 将输出转换为寄存器
);
    // 应用前向寄存器重定时，将寄存器移至组合逻辑之后
    wire z_comb;
    assign z_comb = ~(x & y);
    
    // 添加寄存器以实现前向重定时
    always @(z_comb) begin
        #1.5 z <= z_comb;  // 减少时延，保持总延迟相似
    end
endmodule