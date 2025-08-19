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
    wire [1:0] target_floor;
    wire [1:0] current_floor;
    wire [1:0] state;
    wire [1:0] next_state;

    // State definitions
    parameter [1:0] IDLE = 2'b00, MOVING_UP = 2'b01, 
                    MOVING_DOWN = 2'b10, DOOR_OPENING = 2'b11;

    // State Machine Module
    state_machine sm (
        .clk(clk),
        .reset(reset),
        .at_floor(at_floor),
        .floor_request(floor_request),
        .next_state(next_state),
        .current_floor(current_floor),
        .target_floor(target_floor),
        .state(state)
    );

    // Control Logic Module
    control_logic cl (
        .clk(clk),
        .reset(reset),
        .state(state),
        .at_floor(at_floor),
        .door_closed(door_closed),
        .motor_control(motor_control),
        .door_open(door_open),
        .next_state(next_state)
    );

endmodule

module state_machine(
    input wire clk,
    input wire reset,
    input wire at_floor,
    input wire [3:0] floor_request,
    output reg [1:0] next_state,
    output reg [1:0] current_floor,
    output reg [1:0] target_floor,
    output reg [1:0] state
);
    parameter [1:0] IDLE = 2'b00, MOVING_UP = 2'b01, 
                    MOVING_DOWN = 2'b10, DOOR_OPENING = 2'b11;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            current_floor <= 2'b00;
            target_floor <= 2'b00;
        end else begin
            state <= next_state;
            if (at_floor && (state == MOVING_UP || state == MOVING_DOWN))
                current_floor <= target_floor;
        end
    end

    always @(*) begin
        next_state = state;
        if (|floor_request) begin
            if (floor_request[3:2] != 2'b00) begin
                next_state = MOVING_UP;
                target_floor = floor_request[3] ? 2'b11 : 2'b10;
            end else if (floor_request[1:0] != 2'b00) begin
                next_state = MOVING_DOWN;
                target_floor = floor_request[0] ? 2'b00 : 2'b01;
            end
        end
    end
endmodule

module control_logic(
    input wire clk,
    input wire reset,
    input wire [1:0] state,
    input wire at_floor,
    input wire door_closed,
    output reg [1:0] motor_control, // 00:stop, 01:up, 10:down
    output reg door_open,
    output reg [1:0] next_state
);
    parameter [1:0] IDLE = 2'b00, MOVING_UP = 2'b01, 
                    MOVING_DOWN = 2'b10, DOOR_OPENING = 2'b11;

    always @(*) begin
        motor_control = 2'b00;
        door_open = 1'b0;
        
        case (state)
            IDLE: begin
                door_open = 1'b1;
                if (next_state == MOVING_UP) begin
                    motor_control = 2'b01;
                end else if (next_state == MOVING_DOWN) begin
                    motor_control = 2'b10;
                end
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