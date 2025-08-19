//SystemVerilog
module digital_clock(
    input wire clk,
    input wire rst,
    input wire [1:0] mode,
    input wire inc_value,
    output reg [5:0] hours,
    output reg [5:0] minutes,
    output reg [5:0] seconds
);

    parameter [1:0] NORMAL = 2'b00, SET_HOUR = 2'b01, 
                    SET_MIN = 2'b10, UPDATE = 2'b11;
    
    reg [1:0] state_stage1, state_stage2, next_state;
    reg [16:0] prescaler_stage1, prescaler_stage2;
    reg [5:0] seconds_stage1, seconds_stage2;
    reg [5:0] minutes_stage1, minutes_stage2;
    reg [5:0] hours_stage1, hours_stage2;
    reg inc_value_stage1;
    reg [1:0] mode_stage1;
    
    // Stage 1: Input sampling and prescaler
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_stage1 <= NORMAL;
            prescaler_stage1 <= 17'd0;
            seconds_stage1 <= 6'd0;
            minutes_stage1 <= 6'd0;
            hours_stage1 <= 6'd0;
            inc_value_stage1 <= 1'b0;
            mode_stage1 <= 2'b00;
        end else begin
            state_stage1 <= next_state;
            inc_value_stage1 <= inc_value;
            mode_stage1 <= mode;
            
            case (state_stage1)
                NORMAL: begin
                    prescaler_stage1 <= prescaler_stage1 + 1'b1;
                    if (prescaler_stage1 >= 17'd99999) begin
                        prescaler_stage1 <= 17'd0;
                        seconds_stage1 <= seconds + 1'b1;
                    end
                end
                SET_HOUR: begin
                    if (inc_value_stage1) begin
                        hours_stage1 <= (hours >= 6'd23) ? 6'd0 : hours + 1'b1;
                    end
                end
                SET_MIN: begin
                    if (inc_value_stage1) begin
                        minutes_stage1 <= (minutes >= 6'd59) ? 6'd0 : minutes + 1'b1;
                    end
                end
            endcase
        end
    end

    // Stage 2: Time calculation and rollover
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_stage2 <= NORMAL;
            prescaler_stage2 <= 17'd0;
            seconds_stage2 <= 6'd0;
            minutes_stage2 <= 6'd0;
            hours_stage2 <= 6'd0;
        end else begin
            state_stage2 <= state_stage1;
            prescaler_stage2 <= prescaler_stage1;
            seconds_stage2 <= seconds_stage1;
            minutes_stage2 <= minutes_stage1;
            hours_stage2 <= hours_stage1;
            
            if (state_stage2 == NORMAL && seconds_stage1 >= 6'd59) begin
                seconds_stage2 <= 6'd0;
                minutes_stage2 <= minutes_stage1 + 1'b1;
                if (minutes_stage1 >= 6'd59) begin
                    minutes_stage2 <= 6'd0;
                    hours_stage2 <= hours_stage1 + 1'b1;
                    if (hours_stage1 >= 6'd23)
                        hours_stage2 <= 6'd0;
                end
            end
        end
    end

    // Output stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            seconds <= 6'd0;
            minutes <= 6'd0;
            hours <= 6'd0;
        end else begin
            seconds <= seconds_stage2;
            minutes <= minutes_stage2;
            hours <= hours_stage2;
        end
    end
    
    // Next state logic
    always @(*) begin
        case (mode_stage1)
            2'b00: next_state = NORMAL;
            2'b01: next_state = SET_HOUR;
            2'b10: next_state = SET_MIN;
            default: next_state = NORMAL;
        endcase
    end
endmodule