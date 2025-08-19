module parking_counter(
    input wire clk,
    input wire reset,
    input wire car_entry,
    input wire car_exit,
    output reg [6:0] available_spaces,
    output reg lot_full
);
    parameter [1:0] IDLE = 2'b00, ENTRY = 2'b01, 
                    EXIT = 2'b10, UPDATE = 2'b11;
    parameter MAX_SPACES = 7'd100;
    
    reg [1:0] state, next_state;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            available_spaces <= MAX_SPACES;
            lot_full <= 1'b0;
        end else begin
            state <= next_state;
            
            case (state)
                ENTRY: begin
                    if (available_spaces > 0)
                        available_spaces <= available_spaces - 1'b1;
                end
                EXIT: begin
                    if (available_spaces < MAX_SPACES)
                        available_spaces <= available_spaces + 1'b1;
                end
            endcase
            
            lot_full <= (available_spaces == 0);
        end
    end
    
    always @(*) begin
        case (state)
            IDLE: begin
                if (car_entry)
                    next_state = ENTRY;
                else if (car_exit)
                    next_state = EXIT;
                else
                    next_state = IDLE;
            end
            ENTRY, EXIT: begin
                next_state = UPDATE;
            end
            UPDATE: begin
                if (car_entry && !car_exit)
                    next_state = ENTRY;
                else if (!car_entry && car_exit)
                    next_state = EXIT;
                else
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule