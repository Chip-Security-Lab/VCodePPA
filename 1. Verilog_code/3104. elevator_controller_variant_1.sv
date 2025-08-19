//SystemVerilog
module elevator_controller(
    input wire clk,
    input wire reset,
    input wire [3:0] floor_request,
    input wire door_closed,
    input wire at_floor,
    output reg [1:0] motor_control, // 00:stop, 01:up, 10:down
    output reg door_open
);
    parameter [1:0] IDLE = 2'b00, MOVING_UP = 2'b01, 
                    MOVING_DOWN = 2'b10, DOOR_OPENING = 2'b11;
    reg [1:0] state, next_state;
    reg [1:0] current_floor, target_floor;

    // Pipeline register for state and target_floor
    reg [1:0] state_reg, target_floor_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            current_floor <= 2'b00;
            target_floor <= 2'b00;
            state_reg <= IDLE;
            target_floor_reg <= 2'b00;
        end else begin
            state <= next_state;
            state_reg <= next_state; // Update pipeline register
            if (at_floor && (state == MOVING_UP || state == MOVING_DOWN))
                current_floor <= target_floor_reg; // Use pipelined target_floor
        end
    end

    always @(*) begin
        next_state = state;
        motor_control = 2'b00;
        door_open = 1'b0;
        target_floor_reg = target_floor; // Update target_floor register

        case (state)
            IDLE: begin
                if (|floor_request) begin
                    if (floor_request[3] || floor_request[2]) begin
                        next_state = MOVING_UP;
                        target_floor = floor_request[3] ? 2'b11 : 2'b10;
                    end else begin
                        next_state = MOVING_DOWN;
                        target_floor = floor_request[0] ? 2'b00 : 2'b01;
                    end
                end
                door_open = 1'b1;
            end
            MOVING_UP: begin
                motor_control = 2'b01;
                if (at_floor) next_state = DOOR_OPENING;
            end
            MOVING_DOWN: begin
                motor_control = 2'b10;
                if (at_floor) next_state = DOOR_OPENING;
            end
            DOOR_OPENING: begin
                door_open = 1'b1;
                if (door_closed) next_state = IDLE;
            end
        endcase
    end
endmodule