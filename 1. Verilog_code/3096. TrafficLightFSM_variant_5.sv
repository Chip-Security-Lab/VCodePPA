//SystemVerilog
module TrafficLightFSM #(
    parameter GREEN_TIME = 30,
    parameter YELLOW_TIME = 5,
    parameter SENSOR_DELAY = 10
)(
    input clk, rst_n,
    input vehicle_sensor,
    output reg [2:0] lights
);

    localparam RED    = 4'b1110;
    localparam GREEN  = 4'b1101;
    localparam YELLOW = 4'b1011;
    localparam RESET  = 4'b0111;

    // Pipeline stage 1: State and timer update
    reg [3:0] current_state_stage1, next_state_stage1;
    reg [7:0] timer_stage1;
    reg sensor_reg_stage1;
    
    // Pipeline stage 2: Timer increment and sensor processing
    reg [3:0] current_state_stage2;
    reg [7:0] timer_stage2;
    reg sensor_reg_stage2;
    reg [7:0] timer_inc_stage2;
    
    // Pipeline stage 3: Light control and state transition
    reg [3:0] current_state_stage3;
    reg [7:0] timer_stage3;
    reg [2:0] lights_stage3;

    // Stage 1: State and timer update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state_stage1 <= RESET;
            timer_stage1 <= 0;
            sensor_reg_stage1 <= 0;
        end else begin
            current_state_stage1 <= next_state_stage1;
            sensor_reg_stage1 <= vehicle_sensor;
            timer_stage1 <= timer_inc_stage2;
        end
    end

    // Stage 2: Timer increment and sensor processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state_stage2 <= RESET;
            timer_stage2 <= 0;
            sensor_reg_stage2 <= 0;
            timer_inc_stage2 <= 0;
        end else begin
            current_state_stage2 <= current_state_stage1;
            sensor_reg_stage2 <= sensor_reg_stage1;
            
            if (current_state_stage1 != next_state_stage1) begin
                timer_inc_stage2 <= 0;
            end else begin
                timer_inc_stage2 <= timer_stage1 + 1;
            end
        end
    end

    // Stage 3: Light control and state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state_stage3 <= RESET;
            timer_stage3 <= 0;
            lights_stage3 <= 3'b100;
        end else begin
            current_state_stage3 <= current_state_stage2;
            timer_stage3 <= timer_stage2;
            
            case(current_state_stage2)
                RED:    lights_stage3 <= 3'b100;
                GREEN:  begin
                    lights_stage3 <= 3'b001;
                    if (sensor_reg_stage2 && timer_stage2 >= (GREEN_TIME - SENSOR_DELAY))
                        timer_inc_stage2 <= GREEN_TIME - SENSOR_DELAY;
                end
                YELLOW: lights_stage3 <= 3'b010;
                RESET:  lights_stage3 <= 3'b100;
                default: lights_stage3 <= 3'b100;
            endcase
        end
    end

    // Next state logic
    always @(*) begin
        next_state_stage1 = current_state_stage1;
        case(current_state_stage1)
            RED:    if (timer_stage1 >= 15) next_state_stage1 = GREEN;
            GREEN:  if (timer_stage1 >= GREEN_TIME) next_state_stage1 = YELLOW;
            YELLOW: if (timer_stage1 >= YELLOW_TIME) next_state_stage1 = RED;
            RESET:  next_state_stage1 = RED;
            default: next_state_stage1 = RESET;
        endcase
    end

    // Output assignment
    assign lights = lights_stage3;

endmodule