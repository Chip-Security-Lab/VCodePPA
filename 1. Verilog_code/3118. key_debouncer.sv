module key_debouncer(
    input wire clk,
    input wire reset,
    input wire key_in,
    output reg key_pressed,
    output reg key_released
);
    parameter [1:0] IDLE = 2'b00, DETECTED = 2'b01, 
                    PRESSED = 2'b10, RELEASED = 2'b11;
    reg [1:0] state, next_state;
    reg [15:0] debounce_counter;
    parameter DEBOUNCE_TIME = 16'd1000; // Adjust based on clock frequency
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            debounce_counter <= 16'd0;
            key_pressed <= 1'b0;
            key_released <= 1'b0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    key_pressed <= 1'b0;
                    key_released <= 1'b0;
                    debounce_counter <= 16'd0;
                end
                DETECTED: begin
                    debounce_counter <= debounce_counter + 1'b1;
                end
                PRESSED: begin
                    key_pressed <= 1'b1;
                    key_released <= 1'b0;
                end
                RELEASED: begin
                    key_pressed <= 1'b0;
                    key_released <= 1'b1;
                end
            endcase
        end
    end
    
    always @(*) begin
        case (state)
            IDLE: begin
                if (key_in)
                    next_state = DETECTED;
                else
                    next_state = IDLE;
            end
            DETECTED: begin
                if (!key_in)
                    next_state = IDLE;
                else if (debounce_counter >= DEBOUNCE_TIME)
                    next_state = PRESSED;
                else
                    next_state = DETECTED;
            end
            PRESSED: begin
                if (!key_in)
                    next_state = RELEASED;
                else
                    next_state = PRESSED;
            end
            RELEASED: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule
