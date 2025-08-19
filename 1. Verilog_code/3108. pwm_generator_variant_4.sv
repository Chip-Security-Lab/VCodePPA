//SystemVerilog
// SystemVerilog
module pwm_generator(
    input wire clk,
    input wire reset,
    input wire [7:0] duty_cycle,
    input wire [1:0] mode, // 00:off, 01:normal, 10:inverted, 11:center-aligned
    output reg pwm_out
);
    localparam [1:0] OFF = 2'b00, NORMAL = 2'b01, 
                    INVERTED = 2'b10, CENTER = 2'b11;
    
    reg [1:0] state;
    reg [7:0] counter;
    reg direction; // 0:up, 1:down
    
    // 优化的计数器递增逻辑
    wire [7:0] counter_plus_1 = counter + 8'd1;
    wire counter_max = &counter; // 当counter为8'hFF时为1
    wire counter_min = ~|counter; // 当counter为8'h00时为1
    
    // 优化的状态转换逻辑
    wire [1:0] next_state = mode;
    
    // 优化的PWM输出比较逻辑
    wire pwm_normal = counter < duty_cycle;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= OFF;
            counter <= 8'h00;
            direction <= 1'b0;
        end else begin
            state <= next_state;
            
            case (state)
                OFF: 
                    counter <= 8'h00;
                NORMAL, INVERTED: 
                    counter <= counter_plus_1;
                CENTER: begin
                    if (!direction) begin
                        if (counter_max)
                            direction <= 1'b1;
                        else
                            counter <= counter_plus_1;
                    end else begin
                        if (counter_min)
                            direction <= 1'b0;
                        else
                            counter <= counter - 8'd1;
                    end
                end
                default:
                    counter <= counter;
            endcase
        end
    end
    
    always @(*) begin
        case (state)
            OFF:      pwm_out = 1'b0;
            NORMAL:   pwm_out = pwm_normal;
            INVERTED: pwm_out = ~pwm_normal;
            CENTER:   pwm_out = pwm_normal;
            default:  pwm_out = 1'b0;
        endcase
    end
endmodule