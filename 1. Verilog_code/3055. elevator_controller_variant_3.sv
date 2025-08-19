//SystemVerilog
module elevator_controller(
    input wire clk, reset,
    input wire [3:0] floor_request,
    input wire up_down, // 0:up, 1:down
    output reg [3:0] current_floor,
    output reg moving, door_open
);
    localparam IDLE=2'b00, MOVING=2'b01, DOOR_OPENING=2'b10, DOOR_CLOSING=2'b11;
    reg [1:0] state, next;
    reg [3:0] target_floor;
    reg [3:0] timer;
    
    // Pipeline registers for critical path optimization
    reg [3:0] floor_request_pipe;
    reg [3:0] target_floor_pipe;
    reg [1:0] state_pipe;
    reg [3:0] current_floor_pipe;
    
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE; 
            current_floor <= 4'd0; 
            timer <= 4'd0;
            floor_request_pipe <= 4'd0;
            target_floor_pipe <= 4'd0;
            state_pipe <= IDLE;
            current_floor_pipe <= 4'd0;
        end else begin
            // Pipeline stage 1
            floor_request_pipe <= floor_request;
            state_pipe <= state;
            current_floor_pipe <= current_floor;
            
            // Pipeline stage 2
            state <= next;
            if (state_pipe == MOVING) begin
                current_floor <= (current_floor_pipe < target_floor_pipe) ? 
                               current_floor_pipe + 1 : current_floor_pipe - 1;
            end
            timer <= (state_pipe != next) ? 4'd0 : timer + 4'd1;
        end
    end
    
    always @(*) begin
        moving = (state_pipe == MOVING);
        door_open = (state_pipe == DOOR_OPENING);
        next = state_pipe;
        target_floor = target_floor_pipe;
        
        case (state_pipe)
            IDLE: if (floor_request_pipe != 0) begin
                target_floor = floor_request_pipe;
                next = (current_floor_pipe != target_floor) ? MOVING : DOOR_OPENING;
            end
            MOVING: if (current_floor_pipe == target_floor_pipe) next = DOOR_OPENING;
            DOOR_OPENING: if (timer >= 4'd10) next = DOOR_CLOSING;
            DOOR_CLOSING: if (timer >= 4'd5) next = IDLE;
        endcase
    end
endmodule