//SystemVerilog
`timescale 1ns/1ps
module DelayedNOT(
    input a,          // 将保留原始端口,但会作为控制信号使用
    output reg [7:0] y // 输出结果为8位
);
    // 内部信号定义
    reg [7:0] dividend;       // 被除数
    reg [7:0] divisor;        // 除数
    reg [7:0] quotient;       // 商
    reg [8:0] remainder;      // 余数(需要多一位)
    reg [3:0] count;          // 计数器,用于控制迭代次数
    reg start, done;          // 控制信号
    
    // 不恢复余数除法器状态机
    localparam IDLE = 2'b00, COMPUTE = 2'b01, FINISH = 2'b10;
    reg [1:0] state, next_state;
    
    // 状态机和除法运算控制
    always @(posedge a or negedge a) begin
        if (a) begin
            // 初始化操作数
            dividend <= 8'h64;  // 示例值100
            divisor <= 8'h08;   // 示例值8
            quotient <= 8'h00;
            remainder <= 9'h000;
            count <= 4'h0;
            start <= 1'b1;
            done <= 1'b0;
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        remainder <= {1'b0, dividend};
                        count <= 4'h8;  // 8位需要8次迭代
                        state <= COMPUTE;
                        start <= 1'b0;
                    end
                end
                
                COMPUTE: begin
                    // 左移余数
                    remainder <= {remainder[7:0], 1'b0};
                    
                    // 试减
                    if (remainder[8] == 1'b0) begin
                        // 如果余数是正的,执行减法
                        remainder <= {remainder[7:0], 1'b0} - {1'b0, divisor};
                    end
                    else begin
                        // 如果余数是负的,执行加法
                        remainder <= {remainder[7:0], 1'b0} + {1'b0, divisor};
                    end
                    
                    // 设置商位
                    if (remainder[8] == 1'b0) begin
                        quotient <= {quotient[6:0], 1'b1};  // 余数为正,商位为1
                    end
                    else begin
                        quotient <= {quotient[6:0], 1'b0};  // 余数为负,商位为0
                    end
                    
                    // 计数器递减
                    count <= count - 1'b1;
                    
                    // 检查是否完成所有迭代
                    if (count == 4'h1) begin
                        state <= FINISH;
                    end
                end
                
                FINISH: begin
                    // 修正最后的余数(如果为负)
                    if (remainder[8] == 1'b1) begin
                        remainder <= remainder + {1'b0, divisor};
                    end
                    done <= 1'b1;
                    y <= quotient;  // 将商结果输出
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule