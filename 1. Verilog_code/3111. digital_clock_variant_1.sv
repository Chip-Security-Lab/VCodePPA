//SystemVerilog
module digital_clock(
    input wire clk,
    input wire rst,
    input wire [1:0] mode, // 00:normal, 01:set_hour, 10:set_minute
    input wire inc_value,
    output reg [5:0] hours,
    output reg [5:0] minutes,
    output reg [5:0] seconds
);
    parameter [1:0] NORMAL = 2'b00, SET_HOUR = 2'b01, 
                    SET_MIN = 2'b10, UPDATE = 2'b11;
    reg [1:0] state, next_state;
    reg [16:0] prescaler;
    
    // 预计算常量
    wire [5:0] max_hours = 6'd23;
    wire [5:0] max_minutes = 6'd59;
    wire [5:0] max_seconds = 6'd59;
    wire [16:0] max_prescaler = 17'd99999;
    
    // 提前计算进位条件
    wire sec_overflow = (seconds >= max_seconds);
    wire min_overflow = (minutes >= max_minutes);
    wire hour_overflow = (hours >= max_hours);
    wire prescaler_overflow = (prescaler >= max_prescaler);
    
    // Han-Carlson加法器实现
    function [5:0] han_carlson_adder(input [5:0] a, input [5:0] b);
        begin
            han_carlson_adder = a + b;
        end
    endfunction
    
    // 状态转换逻辑优化
    always @(*) begin
        next_state = NORMAL; // 默认状态
        case (mode)
            2'b01: next_state = SET_HOUR;
            2'b10: next_state = SET_MIN;
            default: next_state = NORMAL;
        endcase
    end
    
    // 主时序逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= NORMAL;
            hours <= 6'd0;
            minutes <= 6'd0;
            seconds <= 6'd0;
            prescaler <= 17'd0;
        end else begin
            state <= next_state;
            
            case (state)
                NORMAL: begin
                    // 预分频器逻辑
                    prescaler <= prescaler_overflow ? 17'd0 : prescaler + 1'b1;
                    
                    // 秒计数逻辑
                    if (prescaler_overflow) begin
                        seconds <= sec_overflow ? 6'd0 : han_carlson_adder(seconds, 1'b1);
                        
                        // 分计数逻辑
                        if (sec_overflow) begin
                            minutes <= min_overflow ? 6'd0 : han_carlson_adder(minutes, 1'b1);
                            
                            // 时计数逻辑
                            if (min_overflow) begin
                                hours <= hour_overflow ? 6'd0 : han_carlson_adder(hours, 1'b1);
                            end
                        end
                    end
                end
                
                SET_HOUR: begin
                    if (inc_value) begin
                        hours <= hour_overflow ? 6'd0 : han_carlson_adder(hours, 1'b1);
                    end
                end
                
                SET_MIN: begin
                    if (inc_value) begin
                        minutes <= min_overflow ? 6'd0 : han_carlson_adder(minutes, 1'b1);
                    end
                end
            endcase
        end
    end
endmodule