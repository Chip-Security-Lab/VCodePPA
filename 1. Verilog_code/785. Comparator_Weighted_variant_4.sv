//SystemVerilog
module Comparator_Weighted #(
    parameter WIDTH = 8,
    parameter [WIDTH-1:0] WEIGHT = 8'b1000_0001
)(
    input  [WIDTH-1:0] vector_a,
    input  [WIDTH-1:0] vector_b,
    output             a_gt_b
);

    // 状态定义
    localparam IDLE = 2'b00;
    localparam CALC_A = 2'b01;
    localparam CALC_B = 2'b10;
    localparam DONE = 2'b11;

    // 寄存器定义
    reg [1:0] state, next_state;
    reg [31:0] sum_a_reg, sum_b_reg;
    reg [3:0] counter;
    reg [WIDTH-1:0] current_vector;
    reg [31:0] current_sum;

    // 组合逻辑：状态转移
    always @(*) begin
        case (state)
            IDLE: next_state = CALC_A;
            CALC_A: next_state = (counter == WIDTH-1) ? CALC_B : CALC_A;
            CALC_B: next_state = (counter == WIDTH-1) ? DONE : CALC_B;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // 组合逻辑：计算当前位的加权值
    wire [31:0] weighted_bit = current_vector[counter] * WEIGHT[counter];

    // 时序逻辑：状态寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end

    // 时序逻辑：计数器
    always @(posedge clk or posedge rst) begin
        if (rst) counter <= 0;
        else if (state == IDLE) counter <= 0;
        else counter <= counter + 1;
    end

    // 时序逻辑：当前向量选择
    always @(posedge clk or posedge rst) begin
        if (rst) current_vector <= 0;
        else if (state == IDLE) current_vector <= vector_a;
        else if (state == CALC_B && counter == 0) current_vector <= vector_b;
    end

    // 时序逻辑：累加器
    always @(posedge clk or posedge rst) begin
        if (rst) current_sum <= 0;
        else if (state == IDLE) current_sum <= 0;
        else if (state == CALC_B && counter == 0) current_sum <= 0;
        else current_sum <= current_sum + weighted_bit;
    end

    // 时序逻辑：结果寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum_a_reg <= 0;
            sum_b_reg <= 0;
        end
        else begin
            if (state == CALC_B && counter == 0) sum_a_reg <= current_sum;
            if (state == DONE) sum_b_reg <= current_sum;
        end
    end

    // 组合逻辑：比较结果
    assign a_gt_b = (sum_a_reg > sum_b_reg);

    // 时钟和复位信号
    reg clk, rst;
    
    initial begin
        clk = 0;
        rst = 1;
        #10 rst = 0;
    end
    
    always #5 clk = ~clk;

endmodule