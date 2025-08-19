//SystemVerilog
module SequenceDetector #(
    parameter DATA_WIDTH = 8,
    parameter SEQUENCE = 8'b1010_1010
)(
    input clk, rst_n,
    input data_in,
    input enable,
    output reg detected
);
    // 使用localparam代替typedef enum
    localparam IDLE = 1'b0, CHECKING = 1'b1;
    
    // 主状态寄存器
    reg current_state, next_state;
    
    // 为高扇出信号next_state添加缓冲寄存器
    reg next_state_buf1, next_state_buf2;
    
    reg [DATA_WIDTH-1:0] shift_reg;

    // 添加next_state的缓冲寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state_buf1 <= IDLE;
            next_state_buf2 <= IDLE;
        end else begin
            next_state_buf1 <= next_state;
            next_state_buf2 <= next_state;
        end
    end

    // 主状态和移位寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            shift_reg <= 0;
        end else if (enable) begin
            // 使用缓冲后的next_state信号
            current_state <= next_state_buf1;
            // 每个时钟周期移入一位
            shift_reg <= {shift_reg[DATA_WIDTH-2:0], data_in};
        end
    end

    // 组合逻辑部分 - 计算next_state和detected
    always @(*) begin
        next_state = current_state;
        detected = 0;
        
        case (current_state)
            IDLE: if (enable) next_state = CHECKING;
            CHECKING: begin
                detected = (shift_reg == SEQUENCE);
                next_state = CHECKING;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule