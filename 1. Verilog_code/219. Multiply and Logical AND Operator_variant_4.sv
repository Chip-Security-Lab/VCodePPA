//SystemVerilog
module multiply_and_operator (
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] product,
    output reg [7:0] and_result
);

    reg [1:0] state, next_state;
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    // 状态寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 下一状态逻辑
    always @(*) begin
        next_state = state; // 默认保持当前状态
        
        case (state)
            IDLE: begin
                if (valid && ready)
                    next_state = CALC;
            end
            CALC: begin
                next_state = DONE;
            end
            DONE: begin
                if (!valid)
                    next_state = IDLE;
            end
        endcase
    end
    
    // ready信号控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    if (valid && ready)
                        ready <= 1'b0;
                end
                CALC: begin
                    ready <= 1'b0;
                end
                DONE: begin
                    ready <= 1'b1;
                end
            endcase
        end
    end
    
    // 乘法运算控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 16'b0;
        end else if (state == CALC) begin
            product <= a * b;
        end
    end
    
    // 与运算控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result <= 8'b0;
        end else if (state == CALC) begin
            and_result <= a & b;
        end
    end

endmodule