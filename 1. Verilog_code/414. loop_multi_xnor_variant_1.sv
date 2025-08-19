//SystemVerilog
module loop_multi_xnor (
    input wire [7:0] input_vecA, input_vecB,
    output reg [7:0] output_vec,
    input wire clk, rst_n,
    input wire start,
    output reg done
);
    parameter LENGTH = 8;
    
    // 乘法器状态机状态
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam FINISH = 2'b10;
    
    // 内部信号定义
    reg [1:0] state, next_state;
    reg [7:0] multiplicand;      // 被乘数
    reg [7:0] multiplier;        // 乘数
    reg [15:0] product;          // 乘积结果
    reg [3:0] bit_counter;       // 位计数器
    
    // 状态寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 状态转换逻辑
    always @(*) begin
        case (state)
            IDLE: next_state = start ? CALC : IDLE;
            CALC: next_state = (bit_counter == 8) ? FINISH : CALC;
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 数据路径控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            multiplicand <= 8'b0;
            multiplier <= 8'b0;
            product <= 16'b0;
            bit_counter <= 4'b0;
            done <= 1'b0;
            output_vec <= 8'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        multiplicand <= input_vecA;
                        multiplier <= input_vecB;
                        product <= 16'b0;
                        bit_counter <= 4'b0;
                        done <= 1'b0;
                    end
                end
                
                CALC: begin
                    // 如果当前乘数位为1，加上被乘数
                    if (multiplier[0]) begin
                        product <= product + {8'b0, multiplicand};
                    end
                    
                    // 乘数右移，被乘数左移
                    multiplier <= multiplier >> 1;
                    multiplicand <= multiplicand << 1;
                    bit_counter <= bit_counter + 1;
                end
                
                FINISH: begin
                    output_vec <= product[7:0];  // 只取低8位作为结果
                    done <= 1'b1;
                end
                
                default: begin
                    // 默认不做任何操作
                end
            endcase
        end
    end
    
endmodule