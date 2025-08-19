//SystemVerilog
module pwm_generator(
    input wire clk,
    input wire reset,
    input wire [7:0] duty_cycle,
    input wire [1:0] mode, // 00:off, 01:normal, 10:inverted, 11:center-aligned
    output reg pwm_out
);
    parameter [1:0] OFF = 2'b00, NORMAL = 2'b01, 
                    INVERTED = 2'b10, CENTER = 2'b11;
    
    // 状态寄存器
    reg [1:0] state, next_state;
    // 计数器和方向控制
    reg [7:0] counter;
    reg direction; // 0:up, 1:down
    
    // 状态转换逻辑
    always @(*) begin
        case (mode)
            2'b00: next_state = OFF;
            2'b01: next_state = NORMAL;
            2'b10: next_state = INVERTED;
            2'b11: next_state = CENTER;
            default: next_state = OFF;
        endcase
    end
    
    // 状态寄存器更新
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= OFF;
        end else begin
            state <= next_state;
        end
    end
    
    // 计数器控制逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 8'h00;
            direction <= 0;
        end else begin
            case (state)
                OFF: begin
                    counter <= 8'h00;
                end
                NORMAL, INVERTED: begin
                    counter <= counter + 1'b1;
                end
                CENTER: begin
                    if (direction == 0) begin
                        if (counter == 8'hFF) begin
                            direction <= 1;
                        end else begin
                            counter <= counter + 1'b1;
                        end
                    end else begin
                        if (counter == 8'h00) begin
                            direction <= 0;
                        end else begin
                            counter <= counter - 1'b1;
                        end
                    end
                end
                default: begin
                    counter <= counter;
                end
            endcase
        end
    end
    
    // PWM输出逻辑
    always @(*) begin
        case (state)
            OFF: begin
                pwm_out = 1'b0;
            end
            NORMAL: begin
                pwm_out = (counter < duty_cycle) ? 1'b1 : 1'b0;
            end
            INVERTED: begin
                pwm_out = (counter < duty_cycle) ? 1'b0 : 1'b1;
            end
            CENTER: begin
                pwm_out = (counter < duty_cycle) ? 1'b1 : 1'b0;
            end
            default: begin
                pwm_out = 1'b0;
            end
        endcase
    end
    
endmodule