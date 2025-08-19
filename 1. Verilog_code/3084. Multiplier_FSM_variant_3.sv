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
    // 状态定义
    localparam IDLE = 3'b000, INIT = 3'b001, ADD = 3'b010, SHIFT = 3'b011, DONE = 3'b100;
    reg [2:0] current_state, next_state;
    
    // 数据路径信号
    reg [WIDTH-1:0] mplier;
    reg [2*WIDTH-1:0] accum;
    reg [3:0] counter;
    reg [WIDTH-1:0] mcand_reg;
    reg add_enable;

    // 状态寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            current_state <= IDLE;
        else 
            current_state <= next_state;
    end

    // 次态逻辑
    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE:   next_state = start ? INIT : IDLE;
            INIT:   next_state = ADD;
            ADD:    next_state = SHIFT;
            SHIFT:  next_state = (counter == WIDTH-1) ? DONE : ADD;
            DONE:   next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // 生成加法使能信号
    always @(*) begin
        add_enable = mplier[0] && (current_state == ADD);
    end

    // 初始化控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mplier <= 0;
            mcand_reg <= 0;
            counter <= 0;
        end else if (current_state == INIT) begin
            mplier <= multiplier;
            mcand_reg <= multiplicand;
            counter <= 0;
        end else if (current_state == SHIFT) begin
            mplier <= {1'b0, mplier[WIDTH-1:1]};
            counter <= counter + 1;
        end
    end

    // 累加器控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum <= 0;
        end else if (current_state == INIT) begin
            accum <= 0;
        end else if (add_enable) begin
            accum <= accum + {mcand_reg, {WIDTH{1'b0}}};
        end else if (current_state == SHIFT) begin
            accum <= {1'b0, accum[2*WIDTH-1:1]};
        end
    end

    // 输出控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 0;
            done <= 0;
        end else if (current_state == DONE) begin
            product <= accum;
            done <= 1;
        end else begin
            done <= 0;
        end
    end
endmodule