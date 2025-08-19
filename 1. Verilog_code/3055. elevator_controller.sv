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
    
    always @(posedge clk)
        if (reset) begin
            state <= IDLE; current_floor <= 4'd0; timer <= 4'd0;
        end else begin
            state <= next;
            if (state == MOVING)
                current_floor <= (current_floor < target_floor) ? 
                                current_floor + 1 : current_floor - 1;
            timer <= (state != next) ? 4'd0 : timer + 4'd1;
        end
    
    always @(*) begin
        moving = (state == MOVING);
        door_open = (state == DOOR_OPENING);
        next = state;
        
        case (state)
            IDLE: if (floor_request != 0) begin
                target_floor = floor_request;
                next = (current_floor != target_floor) ? MOVING : DOOR_OPENING;
            end
            MOVING: if (current_floor == target_floor) next = DOOR_OPENING;
            DOOR_OPENING: if (timer >= 4'd10) next = DOOR_CLOSING;
            DOOR_CLOSING: if (timer >= 4'd5) next = IDLE;
        endcase
    end
endmodule