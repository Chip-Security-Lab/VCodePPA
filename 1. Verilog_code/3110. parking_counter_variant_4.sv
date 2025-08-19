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
    
    reg [1:0] state_stage1, state_stage2, state_stage3;
    reg [1:0] next_state_stage1, next_state_stage2;
    reg [6:0] spaces_stage1, spaces_stage2, spaces_stage3;
    reg full_stage1, full_stage2, full_stage3;
    reg entry_valid_stage1, exit_valid_stage1;
    reg entry_valid_stage2, exit_valid_stage2;
    
    // Pipeline stage 1: Input validation and state transition
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            entry_valid_stage1 <= 1'b0;
            exit_valid_stage1 <= 1'b0;
            state_stage1 <= IDLE;
            spaces_stage1 <= MAX_SPACES;
            full_stage1 <= 1'b0;
        end else begin
            entry_valid_stage1 <= car_entry && !car_exit;
            exit_valid_stage1 <= !car_entry && car_exit;
            state_stage1 <= next_state_stage1;
            spaces_stage1 <= spaces_stage3;
            full_stage1 <= (spaces_stage3 == 0);
        end
    end
    
    // Pipeline stage 2: State processing and space calculation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            entry_valid_stage2 <= 1'b0;
            exit_valid_stage2 <= 1'b0;
            state_stage2 <= IDLE;
            spaces_stage2 <= MAX_SPACES;
            full_stage2 <= 1'b0;
        end else begin
            entry_valid_stage2 <= entry_valid_stage1;
            exit_valid_stage2 <= exit_valid_stage1;
            state_stage2 <= state_stage1;
            spaces_stage2 <= spaces_stage1;
            full_stage2 <= full_stage1;
        end
    end
    
    // Pipeline stage 3: Final state update and output
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage3 <= IDLE;
            spaces_stage3 <= MAX_SPACES;
            full_stage3 <= 1'b0;
            available_spaces <= MAX_SPACES;
            lot_full <= 1'b0;
        end else begin
            state_stage3 <= state_stage2;
            spaces_stage3 <= spaces_stage2;
            full_stage3 <= full_stage2;
            
            if (state_stage2 == ENTRY && spaces_stage2 > 0) begin
                spaces_stage3 <= spaces_stage2 - 1'b1;
            end else if (state_stage2 == EXIT && spaces_stage2 < MAX_SPACES) begin
                spaces_stage3 <= spaces_stage2 + 1'b1;
            end
            
            available_spaces <= spaces_stage3;
            lot_full <= full_stage3;
        end
    end
    
    // Combinational next state logic
    always @(*) begin
        case (state_stage1)
            IDLE: begin
                if (entry_valid_stage1)
                    next_state_stage1 = ENTRY;
                else if (exit_valid_stage1)
                    next_state_stage1 = EXIT;
                else
                    next_state_stage1 = IDLE;
            end
            ENTRY, EXIT: begin
                next_state_stage1 = UPDATE;
            end
            UPDATE: begin
                if (entry_valid_stage1)
                    next_state_stage1 = ENTRY;
                else if (exit_valid_stage1)
                    next_state_stage1 = EXIT;
                else
                    next_state_stage1 = IDLE;
            end
            default: next_state_stage1 = IDLE;
        endcase
    end
endmodule