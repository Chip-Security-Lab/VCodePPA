//SystemVerilog
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
    wire space_available;
    wire space_not_full;
    
    assign space_available = |available_spaces;
    assign space_not_full = available_spaces < MAX_SPACES;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            available_spaces <= MAX_SPACES;
            lot_full <= 1'b0;
        end else begin
            state <= next_state;
            
            case (state)
                ENTRY: begin
                    available_spaces <= available_spaces - space_available;
                end
                EXIT: begin
                    available_spaces <= available_spaces + space_not_full;
                end
            endcase
            
            lot_full <= ~space_available;
        end
    end
    
    always @(*) begin
        case (state)
            IDLE: begin
                next_state = car_entry ? ENTRY : 
                           (car_exit ? EXIT : IDLE);
            end
            ENTRY, EXIT: begin
                next_state = UPDATE;
            end
            UPDATE: begin
                next_state = car_entry ? (car_exit ? IDLE : ENTRY) :
                           (car_exit ? EXIT : IDLE);
            end
            default: next_state = IDLE;
        endcase
    end
endmodule