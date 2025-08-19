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
    // 状态定义
    localparam IDLE = 1'b0, CHECKING = 1'b1;
    
    // 内部信号
    reg current_state, next_state;
    reg [DATA_WIDTH-1:0] shift_reg;
    
    // 状态寄存器更新逻辑 - 处理状态转换
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else if (enable) begin
            current_state <= next_state;
        end
    end
    
    // 移位寄存器更新逻辑 - 处理数据采集
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= {DATA_WIDTH{1'b0}};
        end else if (enable) begin
            // 每个时钟周期移入一位
            shift_reg <= {shift_reg[DATA_WIDTH-2:0], data_in};
        end
    end
    
    // 状态转换逻辑 - 处理下一状态计算
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (enable) 
                    next_state = CHECKING;
                else
                    next_state = IDLE;
            end
            
            CHECKING: begin
                next_state = CHECKING;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // 输出逻辑 - 处理检测信号生成
    always @(*) begin
        detected = (current_state == CHECKING) && (shift_reg == SEQUENCE);
    end
    
endmodule