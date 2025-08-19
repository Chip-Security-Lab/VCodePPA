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
                    prescaler <= prescaler + 1'b1;
                    if (prescaler >= 17'd99999) begin // Assuming 1MHz clock for simulation
                        prescaler <= 17'd0;
                        seconds <= seconds + 1'b1;
                        if (seconds >= 6'd59) begin
                            seconds <= 6'd0;
                            minutes <= minutes + 1'b1;
                            if (minutes >= 6'd59) begin
                                minutes <= 6'd0;
                                hours <= hours + 1'b1;
                                if (hours >= 6'd23)
                                    hours <= 6'd0;
                            end
                        end
                    end
                end
                SET_HOUR: begin
                    if (inc_value) begin
                        hours <= (hours >= 6'd23) ? 6'd0 : hours + 1'b1;
                    end
                end
                SET_MIN: begin
                    if (inc_value) begin
                        minutes <= (minutes >= 6'd59) ? 6'd0 : minutes + 1'b1;
                    end
                end
            endcase
        end
    end
    
    always @(*) begin
        case (mode)
            2'b00: next_state = NORMAL;
            2'b01: next_state = SET_HOUR;
            2'b10: next_state = SET_MIN;
            default: next_state = NORMAL;
        endcase
    end
endmodule
