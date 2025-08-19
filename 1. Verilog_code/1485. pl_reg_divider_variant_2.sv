//SystemVerilog
// SystemVerilog
module pl_reg_divider #(parameter W=8, DIV=4) (
    input clk, rst,
    input [W-1:0] data_in,
    output reg [W-1:0] data_out
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    // 寄存器定义
    reg [1:0] state, next_state;
    reg [W-1:0] dividend;       // 被除数
    reg [W-1:0] divisor;        // 除数
    reg [W-1:0] quotient;       // 商
    reg [W:0] partial_remainder; // 部分余数，多一位用于符号判断
    reg [$clog2(W)-1:0] bit_count; // 迭代计数器
    
    // 流水线寄存器和中间信号
    reg [W:0] shifted_remainder;     // 第一阶段：左移部分余数
    reg [W-1:0] shifted_dividend;    // 第一阶段：左移被除数
    reg [W:0] sub_result;            // 第一阶段：减法结果
    reg [W:0] add_result;            // 第一阶段：加法结果
    reg [W:0] operation_result;      // 第二阶段：选择操作结果
    reg [W-1:0] next_quotient;       // 第二阶段：下一个商值
    
    // 非恢复除法状态机
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            data_out <= 0;
            dividend <= 0;
            divisor <= DIV;
            quotient <= 0;
            partial_remainder <= 0;
            bit_count <= 0;
            shifted_remainder <= 0;
            shifted_dividend <= 0;
            sub_result <= 0;
            add_result <= 0;
            operation_result <= 0;
            next_quotient <= 0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    dividend <= data_in;
                    divisor <= DIV;
                    partial_remainder <= 0;
                    bit_count <= 0;
                    quotient <= 0;
                end
                
                CALC: begin
                    // 第一级流水线：计算移位和算术操作
                    shifted_remainder <= {partial_remainder[W-1:0], dividend[W-1]};
                    shifted_dividend <= {dividend[W-2:0], 1'b0};
                    sub_result <= {partial_remainder[W-1:0], dividend[W-1]} - {1'b0, divisor};
                    add_result <= {partial_remainder[W-1:0], dividend[W-1]} + {1'b0, divisor};
                    
                    // 第二级流水线：选择结果和更新
                    dividend <= shifted_dividend;
                    
                    if (partial_remainder[W] == 1'b0) begin
                        operation_result <= sub_result;
                        next_quotient <= {quotient[W-2:0], 1'b1};
                    end else begin
                        operation_result <= add_result;
                        next_quotient <= {quotient[W-2:0], 1'b0};
                    end
                    
                    // 第三级流水线：更新状态
                    partial_remainder <= operation_result;
                    quotient <= next_quotient;
                    bit_count <= bit_count + 1;
                end
                
                DONE: begin
                    // 流水线处理最终结果
                    if (partial_remainder[W] == 1'b1) begin
                        next_quotient <= {quotient[W-1:1], 1'b0};
                        operation_result <= partial_remainder + {1'b0, divisor};
                    end else begin
                        next_quotient <= quotient;
                        operation_result <= partial_remainder;
                    end
                    
                    // 最终更新
                    quotient <= next_quotient;
                    partial_remainder <= operation_result;
                    data_out <= next_quotient;
                end
            endcase
        end
    end
    
    // 组合逻辑：状态转换
    // 由于流水线深度增加，需要延长CALC状态时间
    always @(*) begin
        case (state)
            IDLE: next_state = CALC;
            CALC: next_state = (bit_count == W+1) ? DONE : CALC; // 增加了流水线延迟
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
endmodule