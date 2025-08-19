//SystemVerilog
module Multiplier_FSM #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input start,
    input [WIDTH-1:0] multiplicand, 
    input [WIDTH-1:0] multiplier,
    output reg [2*WIDTH-1:0] product,
    output reg done
);
    // 使用localparam替代typedef enum，保持状态编码不变
    localparam IDLE = 3'b000, INIT = 3'b001, ADD1 = 3'b010, ADD2 = 3'b011, 
               SHIFT = 3'b100, DONE = 3'b101;
    reg [2:0] current_state, next_state;
    
    reg [WIDTH-1:0] mplier;
    reg [2*WIDTH-1:0] accum;
    reg [3:0] counter;
    reg [WIDTH-1:0] mcand_reg; // 存储被乘数
    
    // 关键路径切割寄存器
    reg [WIDTH-1:0] mcand_shifted;       // 存储移位后的被乘数
    reg add_needed;                      // 存储是否需要加法的标志
    reg [WIDTH:0] partial_sum;           // 部分和寄存器
    
    // 状态寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state <= IDLE;
        else current_state <= next_state;
    end

    // 次态逻辑 - 使用显式多路复用器结构
    always @(*) begin
        case(current_state)
            IDLE: begin
                if (start) next_state = INIT;
                else next_state = IDLE;
            end
            INIT: next_state = ADD1;
            ADD1: next_state = ADD2;
            ADD2: next_state = SHIFT;
            SHIFT: begin
                if (counter == WIDTH-1) next_state = DONE;
                else next_state = ADD1;
            end
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // 高位部分加法结果
    reg [WIDTH-1:0] high_sum;
    // 将长加法分解的逻辑
    wire [WIDTH-1:0] low_part_a = accum[WIDTH-1:0];
    wire [WIDTH-1:0] low_part_b = mcand_shifted << (WIDTH-1);
    wire [WIDTH-1:0] high_part_a = accum[2*WIDTH-1:WIDTH];
    wire [WIDTH-1:0] high_part_b = mcand_shifted[WIDTH-1:1];
    
    // 数据路径控制 - 使用显式多路复用器结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum <= 0;
            mplier <= 0;
            mcand_reg <= 0;
            mcand_shifted <= 0;
            add_needed <= 0;
            partial_sum <= 0;
            high_sum <= 0;
            counter <= 0;
            product <= 0;
            done <= 0;
        end else begin
            case(current_state)
                IDLE: begin
                    done <= 0;
                end
                INIT: begin
                    accum <= 0;
                    mplier <= multiplier;
                    mcand_reg <= multiplicand;
                    mcand_shifted <= 0;
                    add_needed <= 0;
                    partial_sum <= 0;
                    high_sum <= 0;
                    counter <= 0;
                    done <= 0;
                end
                ADD1: begin
                    // 第一阶段：准备操作数
                    mcand_shifted <= mcand_reg;
                    add_needed <= mplier[0];
                    done <= 0;
                end
                ADD2: begin
                    // 使用显式多路复用器结构处理加法
                    if (add_needed) begin
                        // 低位部分加法
                        partial_sum <= low_part_a + low_part_b;
                        // 高位部分加法
                        high_sum <= high_part_a + high_part_b;
                        
                        // 更新高位部分
                        accum[2*WIDTH-1:WIDTH] <= high_sum;
                        // 更新低位部分
                        accum[WIDTH-1:0] <= partial_sum[WIDTH-1:0];
                        
                        // 进位处理使用显式多路复用器结构
                        if (partial_sum[WIDTH]) begin
                            accum[WIDTH] <= accum[WIDTH] + 1'b1;
                        end
                    end
                    done <= 0;
                end
                SHIFT: begin
                    // 整体右移
                    accum <= {1'b0, accum[2*WIDTH-1:1]};
                    mplier <= {1'b0, mplier[WIDTH-1:1]};
                    counter <= counter + 1;
                    done <= 0;
                end
                DONE: begin
                    product <= accum;
                    done <= 1;
                end
                default: begin
                    done <= 0;
                end
            endcase
        end
    end
endmodule