//SystemVerilog
module hamming_encoder_with_status(
    input clk, reset, enable,
    input [7:0] data_in,
    output reg [11:0] encoded_data,
    output reg busy, done
);
    // 状态定义
    reg [1:0] state, next_state;
    parameter IDLE = 0, ENCODING = 1, COMPLETE = 2;
    
    // 中间信号定义
    reg [11:0] encoded_data_next;
    
    // 状态转换逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 下一状态逻辑
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: 
                if (enable) next_state = ENCODING;
            ENCODING: 
                next_state = COMPLETE;
            COMPLETE: 
                next_state = IDLE;
            default: 
                next_state = IDLE;
        endcase
    end
    
    // 编码逻辑 - 组合逻辑部分
    always @(*) begin
        encoded_data_next = encoded_data;
        
        if (state == ENCODING) begin
            encoded_data_next[0] = ^(data_in & 8'b10101010);
            encoded_data_next[1] = ^(data_in & 8'b11001100);
            encoded_data_next[2] = ^(data_in & 8'b11110000);
            encoded_data_next[11:3] = {data_in, 1'b0}; // Data + 1 parity bit
        end
    end
    
    // 输出寄存器更新
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            encoded_data <= 12'b0;
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (enable) begin
                        busy <= 1'b1;
                        done <= 1'b0;
                    end
                end
                ENCODING: begin
                    encoded_data <= encoded_data_next;
                end
                COMPLETE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                end
                default: begin
                    busy <= 1'b0;
                    done <= 1'b0;
                end
            endcase
        end
    end
endmodule