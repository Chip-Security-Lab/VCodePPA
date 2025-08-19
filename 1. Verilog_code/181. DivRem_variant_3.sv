//SystemVerilog
module DivRem(
    input clk,
    input rst_n,
    input start,
    input [7:0] num, den,
    output reg [7:0] q, r,
    output reg done
);
    // 内部寄存器和状态定义
    reg [3:0] count;
    reg [7:0] dividend;
    reg [7:0] quotient;
    reg [7:0] divisor;
    reg [7:0] remainder;
    reg calculating;
    
    // 状态定义
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam FINISH = 2'b10;
    reg [1:0] state, next_state;
    
    // 状态转换逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 下一状态逻辑
    always @(*) begin
        case (state)
            IDLE: begin
                if (start) 
                    next_state = CALC;
                else 
                    next_state = IDLE;
            end
            CALC: begin
                if (count == 4'd8) 
                    next_state = FINISH;
                else 
                    next_state = CALC;
            end
            FINISH: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // 二进制长除法算法实现
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 4'd0;
            quotient <= 8'd0;
            remainder <= 8'd0;
            dividend <= 8'd0;
            divisor <= 8'd0;
            q <= 8'd0;
            r <= 8'd0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        // 初始化数据
                        dividend <= num;
                        divisor <= den;
                        quotient <= 8'd0;
                        remainder <= 8'd0;
                        count <= 4'd0;
                        done <= 1'b0;
                    end
                end
                CALC: begin
                    if (divisor == 8'd0) begin
                        // 除零处理
                        quotient <= 8'hFF;
                        remainder <= dividend;
                        count <= 4'd8; // 强制结束
                    end else begin
                        // 移位并检查当前位
                        remainder <= {remainder[6:0], dividend[7]};
                        dividend <= {dividend[6:0], 1'b0};
                        
                        // 如果remainder >= divisor，执行减法并设置商的相应位
                        if ({remainder[6:0], dividend[7]} >= divisor) begin
                            remainder <= {remainder[6:0], dividend[7]} - divisor;
                            quotient <= {quotient[6:0], 1'b1};
                        end else begin
                            quotient <= {quotient[6:0], 1'b0};
                        end
                        
                        count <= count + 4'd1;
                    end
                end
                FINISH: begin
                    // 保存结果并设置完成标志
                    q <= quotient;
                    r <= remainder;
                    done <= 1'b1;
                end
            endcase
        end
    end
endmodule