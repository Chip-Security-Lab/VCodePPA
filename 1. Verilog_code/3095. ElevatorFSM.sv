module ElevatorFSM #(
    parameter FLOORS = 8
)(
    input clk, rst_n,
    input [FLOORS-1:0] call_buttons,
    input emergency,
    output reg [2:0] current_floor,
    output reg doors_open,
    output reg moving_up
);
    // 使用localparam代替typedef enum
    localparam IDLE = 2'b00, MOVING = 2'b01, DOOR_OPEN = 2'b10, EMERGENCY = 2'b11;
    reg [1:0] current_state, next_state;
    
    reg [FLOORS-1:0] pending_calls;
    reg [7:0] door_timer;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            current_floor <= 0;
            pending_calls <= 0;
            door_timer <= 0;
            doors_open <= 0;
            moving_up <= 0;
        end else begin
            current_state <= next_state;
            
            // 处理呼叫按钮
            pending_calls <= pending_calls | call_buttons;
            
            case(current_state)
                IDLE: begin
                    if (|pending_calls) begin
                        // 根据当前楼层和请求确定运行方向
                        moving_up <= (|(pending_calls >> (current_floor + 1)));
                    end
                end
                MOVING: begin
                    if (moving_up && current_floor < FLOORS-1) begin
                        current_floor <= current_floor + 1;
                    end else if (!moving_up && current_floor > 0) begin
                        current_floor <= current_floor - 1;
                    end
                    // 清除当前楼层的呼叫
                    pending_calls[current_floor] <= 0;
                end
                DOOR_OPEN: begin
                    doors_open <= 1;
                    door_timer <= door_timer + 1;
                    if (door_timer >= 100) begin
                        doors_open <= 0;
                    end
                end
                EMERGENCY: begin
                    if (current_floor > 0) begin
                        current_floor <= current_floor - 1;
                    end else begin
                        doors_open <= 1;
                    end
                end
                default: ; // 不做任何操作
            endcase
        end
    end

    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: begin
                if (emergency) next_state = EMERGENCY;
                else if (|pending_calls) next_state = MOVING;
            end
            MOVING: begin
                if (emergency) begin
                    next_state = EMERGENCY;
                end else if (pending_calls[current_floor]) begin
                    next_state = DOOR_OPEN;
                end
            end
            DOOR_OPEN: begin
                if (door_timer >= 100) next_state = IDLE;
            end
            EMERGENCY: begin
                if (!emergency && current_floor == 0) next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule