module pwm_generator(
    input wire clk,
    input wire reset,
    input wire [7:0] duty_cycle,
    input wire [1:0] mode, // 00:off, 01:normal, 10:inverted, 11:center-aligned
    output reg pwm_out
);
    parameter [1:0] OFF = 2'b00, NORMAL = 2'b01, 
                    INVERTED = 2'b10, CENTER = 2'b11;
    reg [1:0] state, next_state;
    reg [7:0] counter;
    reg direction; // 0:up, 1:down
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= OFF;
            counter <= 8'h00;
            direction <= 0;
        end else begin
            state <= next_state;
            
            case (state)
                OFF: counter <= 8'h00;
                NORMAL, INVERTED: counter <= counter + 1;
                CENTER: begin
                    if (direction == 0) begin
                        if (counter == 8'hFF)
                            direction <= 1;
                        else
                            counter <= counter + 1;
                    end else begin
                        if (counter == 8'h00)
                            direction <= 0;
                        else
                            counter <= counter - 1;
                    end
                end
            endcase
        end
    end
    
    always @(*) begin
        next_state = (mode == 2'b00) ? OFF : 
                     (mode == 2'b01) ? NORMAL :
                     (mode == 2'b10) ? INVERTED : CENTER;
                     
        case (state)
            OFF: pwm_out = 1'b0;
            NORMAL: pwm_out = (counter < duty_cycle) ? 1'b1 : 1'b0;
            INVERTED: pwm_out = (counter < duty_cycle) ? 1'b0 : 1'b1;
            CENTER: pwm_out = (counter < duty_cycle) ? 1'b1 : 1'b0;
        endcase
    end
endmodule