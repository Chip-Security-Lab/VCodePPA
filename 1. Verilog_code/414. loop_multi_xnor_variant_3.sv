//SystemVerilog
module loop_multi_xnor (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [LENGTH-1:0] input_vecA, input_vecB,
    output reg [LENGTH-1:0] output_vec,
    output reg done
);
    parameter LENGTH = 8;
    
    // 状态定义
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] current_state, next_state;
    reg [$clog2(LENGTH):0] i; // 计数器变量
    
    // 状态寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    
    // 下一状态逻辑
    always @(*) begin
        case (current_state)
            IDLE: next_state = start ? CALC : IDLE;
            CALC: next_state = (i == LENGTH-1) ? DONE : CALC;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 计数器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i <= 0;
        end else if (current_state == IDLE && next_state == CALC) begin
            i <= 0;
        end else if (current_state == CALC) begin
            i <= i + 1;
        end
    end
    
    // 输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_vec <= 0;
            done <= 0;
        end else begin
            if (current_state == CALC) begin
                output_vec[i] <= ~(input_vecA[i] ^ input_vecB[i]);
            end
            
            if (current_state == DONE) begin
                done <= 1;
            end else begin
                done <= 0;
            end
        end
    end
endmodule