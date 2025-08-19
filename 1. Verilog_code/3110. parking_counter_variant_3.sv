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
    
    // 状态寄存器更新逻辑
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 状态转换逻辑
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
    
    // 车位计数逻辑
    always @(posedge clk or posedge reset) begin
        if (reset)
            available_spaces <= MAX_SPACES;
        else if (state == ENTRY && available_spaces > 0)
            available_spaces <= available_spaces - 1'b1;
        else if (state == EXIT && available_spaces < MAX_SPACES)
            available_spaces <= available_spaces + 1'b1;
    end
    
    // 停车场满状态逻辑
    always @(posedge clk or posedge reset) begin
        if (reset)
            lot_full <= 1'b0;
        else
            lot_full <= (available_spaces == 0);
    end
endmodule