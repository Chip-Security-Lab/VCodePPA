//SystemVerilog
module divider_pipeline_32bit (
    input clk,
    input [31:0] dividend,
    input [31:0] divisor,
    output reg [31:0] quotient,
    output reg [31:0] remainder
);

    // 内部寄存器用于迭代计算
    reg [31:0] dividend_reg;
    reg [31:0] divisor_reg;
    reg [31:0] quotient_temp;
    reg [31:0] remainder_temp;
    reg [5:0] counter; // 计数器，用于跟踪迭代次数
    
    // 状态机状态定义
    localparam IDLE = 2'd0;
    localparam CALC = 2'd1;
    localparam DONE = 2'd2;
    reg [1:0] state;

    always @(posedge clk) begin
        case(state)
            IDLE: begin
                // 初始化
                dividend_reg <= dividend;
                divisor_reg <= divisor;
                quotient_temp <= 32'd0;
                remainder_temp <= 32'd0;
                counter <= 6'd32; // 32位需要32次迭代
                state <= CALC;
            end
            
            CALC: begin
                if (counter > 0) begin
                    // 移位操作，构建当前位的被除数
                    remainder_temp <= {remainder_temp[30:0], dividend_reg[31]};
                    dividend_reg <= {dividend_reg[30:0], 1'b0};
                    
                    // 如果当前remainder >= divisor，执行减法并设置商的对应位为1
                    if ({remainder_temp[30:0], dividend_reg[31]} >= divisor_reg) begin
                        remainder_temp <= {remainder_temp[30:0], dividend_reg[31]} - divisor_reg;
                        quotient_temp <= {quotient_temp[30:0], 1'b1};
                    end else begin
                        quotient_temp <= {quotient_temp[30:0], 1'b0};
                    end
                    
                    counter <= counter - 1'b1;
                end else begin
                    // 计算完成
                    state <= DONE;
                end
            end
            
            DONE: begin
                // 输出最终结果
                quotient <= quotient_temp;
                remainder <= remainder_temp;
                state <= IDLE;
            end
            
            default: state <= IDLE;
        endcase
    end

endmodule