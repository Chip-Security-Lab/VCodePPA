//SystemVerilog
module TrafficLightFSM #(
    parameter GREEN_TIME = 30,
    parameter YELLOW_TIME = 5,
    parameter SENSOR_DELAY = 10,
    parameter RED_TIME = 15
)(
    input clk, rst_n,
    input vehicle_sensor,
    output reg [2:0] lights
);
    localparam [1:0] RED = 2'b00, GREEN = 2'b01, YELLOW = 2'b10;
    localparam [2:0] RED_LIGHT = 3'b100, YELLOW_LIGHT = 3'b010, GREEN_LIGHT = 3'b001;
    
    reg [1:0] current_state, next_state;
    reg [7:0] timer;
    reg sensor_reg, sensor_valid;
    reg [7:0] timer_inv;
    reg [7:0] timer_next;
    
    // 条件反相减法器实现
    always @(*) begin
        timer_inv = ~timer;
        timer_next = timer + 1'b1;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sensor_reg <= 0;
            sensor_valid <= 0;
        end else begin
            sensor_reg <= vehicle_sensor;
            sensor_valid <= sensor_reg && (timer >= (GREEN_TIME - SENSOR_DELAY));
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= RED;
            timer <= 0;
            lights <= RED_LIGHT;
        end else begin
            if (current_state != next_state) begin
                timer <= 0;
                current_state <= next_state;
            end else begin
                timer <= timer_next;
            end
            
            case(current_state)
                RED:    lights <= RED_LIGHT;
                YELLOW: lights <= YELLOW_LIGHT;
                GREEN: begin
                    lights <= GREEN_LIGHT;
                    if (sensor_valid)
                        timer <= ~(GREEN_TIME - SENSOR_DELAY - 1);
                end
                default: lights <= RED_LIGHT;
            endcase
        end
    end

    always @(*) begin
        next_state = current_state;
        
        case(current_state)
            RED:    if (timer >= RED_TIME)     next_state = GREEN;
            GREEN:  if (timer >= GREEN_TIME)   next_state = YELLOW;
            YELLOW: if (timer >= YELLOW_TIME)  next_state = RED;
            default: next_state = RED;
        endcase
    end
endmodule