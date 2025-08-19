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

            if (state == OFF) begin
                counter <= 8'h00;
            end else if (state == NORMAL || state == INVERTED) begin
                counter <= counter + 1;
            end else if (state == CENTER) begin
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
        end
    end
    
    always @(*) begin
        if (mode == 2'b00) begin
            next_state = OFF;
        end else if (mode == 2'b01) begin
            next_state = NORMAL;
        end else if (mode == 2'b10) begin
            next_state = INVERTED;
        end else begin
            next_state = CENTER;
        end
        
        if (state == OFF) begin
            pwm_out = 1'b0;
        end else if (state == NORMAL) begin
            pwm_out = (counter < duty_cycle) ? 1'b1 : 1'b0;
        end else if (state == INVERTED) begin
            pwm_out = (counter < duty_cycle) ? 1'b0 : 1'b1;
        end else if (state == CENTER) begin
            pwm_out = (counter < duty_cycle) ? 1'b1 : 1'b0;
        end
    end
endmodule