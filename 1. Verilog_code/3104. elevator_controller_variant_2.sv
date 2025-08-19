//SystemVerilog
// Top-level module
module elevator_controller(
    input wire clk,
    input wire reset,
    input wire [3:0] floor_request,
    input wire door_closed,
    input wire at_floor,
    output wire [1:0] motor_control,
    output wire door_open,
    output wire valid,
    input wire ready
);

    // Internal signals
    wire [1:0] state;
    wire [1:0] next_state;
    wire [1:0] current_floor;
    wire [1:0] target_floor;
    wire state_update;
    wire [1:0] direction;
    wire request_valid;

    // State definitions
    parameter [1:0] IDLE = 2'b00, MOVING_UP = 2'b01, 
                    MOVING_DOWN = 2'b10, DOOR_OPENING = 2'b11;

    // Floor request decoder
    floor_request_decoder u_floor_decoder(
        .floor_request(floor_request),
        .direction(direction),
        .target_floor(target_floor),
        .request_valid(request_valid)
    );

    // State machine
    elevator_state_machine u_state_machine(
        .clk(clk),
        .reset(reset),
        .direction(direction),
        .at_floor(at_floor),
        .door_closed(door_closed),
        .request_valid(request_valid),
        .state(state),
        .next_state(next_state),
        .state_update(state_update)
    );

    // Floor tracker
    floor_tracker u_floor_tracker(
        .clk(clk),
        .reset(reset),
        .state(state),
        .at_floor(at_floor),
        .target_floor(target_floor),
        .current_floor(current_floor)
    );

    // Control signal generator
    control_signal_generator u_control_gen(
        .state(state),
        .next_state(next_state),
        .motor_control(motor_control),
        .door_open(door_open),
        .valid(valid)
    );

    // Ready signal handler
    ready_handler u_ready_handler(
        .clk(clk),
        .valid(valid),
        .ready(ready)
    );

endmodule

// Floor request decoder module
module floor_request_decoder(
    input wire [3:0] floor_request,
    output reg [1:0] direction,
    output reg [1:0] target_floor,
    output reg request_valid
);
    always @(*) begin
        request_valid = |floor_request;
        if (floor_request[3] || floor_request[2]) begin
            direction = 2'b01; // UP
            target_floor = floor_request[3] ? 2'b11 : 2'b10;
        end else begin
            direction = 2'b10; // DOWN
            target_floor = floor_request[0] ? 2'b00 : 2'b01;
        end
    end
endmodule

// State machine module
module elevator_state_machine(
    input wire clk,
    input wire reset,
    input wire [1:0] direction,
    input wire at_floor,
    input wire door_closed,
    input wire request_valid,
    output reg [1:0] state,
    output reg [1:0] next_state,
    output reg state_update
);
    parameter [1:0] IDLE = 2'b00, MOVING_UP = 2'b01, 
                    MOVING_DOWN = 2'b10, DOOR_OPENING = 2'b11;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            state_update <= 1'b0;
        end else begin
            state <= next_state;
            state_update <= 1'b1;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (request_valid) begin
                    next_state = (direction == 2'b01) ? MOVING_UP : MOVING_DOWN;
                end
            end
            MOVING_UP, MOVING_DOWN: begin
                if (at_floor) next_state = DOOR_OPENING;
            end
            DOOR_OPENING: begin
                if (door_closed) next_state = IDLE;
            end
        endcase
    end
endmodule

// Floor tracker module
module floor_tracker(
    input wire clk,
    input wire reset,
    input wire [1:0] state,
    input wire at_floor,
    input wire [1:0] target_floor,
    output reg [1:0] current_floor
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_floor <= 2'b00;
        end else if (at_floor && (state == 2'b01 || state == 2'b10)) begin
            current_floor <= target_floor;
        end
    end
endmodule

// Control signal generator module
module control_signal_generator(
    input wire [1:0] state,
    input wire [1:0] next_state,
    output reg [1:0] motor_control,
    output reg door_open,
    output reg valid
);
    always @(*) begin
        motor_control = 2'b00;
        door_open = 1'b0;
        valid = 1'b0;

        case (state)
            2'b00: begin // IDLE
                door_open = 1'b1;
                valid = 1'b1;
            end
            2'b01: begin // MOVING_UP
                motor_control = 2'b01;
            end
            2'b10: begin // MOVING_DOWN
                motor_control = 2'b10;
            end
            2'b11: begin // DOOR_OPENING
                door_open = 1'b1;
            end
        endcase
    end
endmodule

// Ready signal handler module
module ready_handler(
    input wire clk,
    input wire valid,
    input wire ready
);
    always @(posedge clk) begin
        if (valid && ready) begin
            // Handle ready signal
        end
    end
endmodule