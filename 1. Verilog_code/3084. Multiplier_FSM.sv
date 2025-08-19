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
    // 使用localparam替代typedef enum
    localparam IDLE = 3'b000, INIT = 3'b001, ADD = 3'b010, SHIFT = 3'b011, DONE = 3'b100;
    reg [2:0] current_state, next_state;
    
    reg [WIDTH-1:0] mplier;
    reg [2*WIDTH-1:0] accum;
    reg [3:0] counter;
    reg [WIDTH-1:0] mcand_reg; // 添加寄存器存储被乘数

    // 状态寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state <= IDLE;
        else current_state <= next_state;
    end

    // 次态逻辑
    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: next_state = start ? INIT : IDLE;
            INIT: next_state = ADD;
            ADD: next_state = SHIFT;
            SHIFT: next_state = (counter == WIDTH-1) ? DONE : ADD;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // 数据路径控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum <= 0;
            mplier <= 0;
            mcand_reg <= 0;
            counter <= 0;
            product <= 0;
            done <= 0;
        end else begin
            done <= 0;
            case(current_state)
                INIT: begin
                    accum <= 0;
                    mplier <= multiplier;
                    mcand_reg <= multiplicand;
                    counter <= 0;
                end
                ADD: if (mplier[0]) accum <= accum + {mcand_reg, {WIDTH{1'b0}}};
                SHIFT: begin
                    accum <= {1'b0, accum[2*WIDTH-1:1]};
                    mplier <= {1'b0, mplier[WIDTH-1:1]};
                    counter <= counter + 1;
                end
                DONE: begin
                    product <= accum;
                    done <= 1;
                end
                default: ; // 默认不操作
            endcase
        end
    end
endmodule