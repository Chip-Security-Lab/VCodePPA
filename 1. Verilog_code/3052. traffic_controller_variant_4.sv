//SystemVerilog
module traffic_controller(
    input wire clock, reset, car_sensor,
    output reg [1:0] main_road, side_road
);
    localparam GREEN=2'b00, YELLOW=2'b01, RED=2'b10;
    localparam S0=2'b00, S1=2'b01, S2=2'b10, S3=2'b11;
    
    reg [1:0] state, next;
    reg [3:0] timer;
    wire timer_ge_9, timer_ge_2;
    wire state_eq_S0, state_eq_S1, state_eq_S2, state_eq_S3;
    wire car_sensor_and_timer_ge_9;
    
    // Pre-compute timer comparisons
    assign timer_ge_9 = (timer >= 9);
    assign timer_ge_2 = (timer >= 2);
    
    // Pre-compute state comparisons
    assign state_eq_S0 = (state == S0);
    assign state_eq_S1 = (state == S1);
    assign state_eq_S2 = (state == S2);
    assign state_eq_S3 = (state == S3);
    
    // Pre-compute complex condition
    assign car_sensor_and_timer_ge_9 = car_sensor & timer_ge_9;
    
    // State transition logic
    always @(*) begin
        next = state; // Default assignment
        if (state_eq_S0 && car_sensor_and_timer_ge_9)
            next = S1;
        else if (state_eq_S1 && timer_ge_2)
            next = S2;
        else if (state_eq_S2 && timer_ge_9)
            next = S3;
        else if (state_eq_S3 && timer_ge_2)
            next = S0;
    end
    
    // Output logic
    always @(*) begin
        main_road = RED;   // Default assignment
        side_road = RED;   // Default assignment
        
        if (state_eq_S0) begin
            main_road = GREEN;
        end
        else if (state_eq_S1) begin
            main_road = YELLOW;
        end
        else if (state_eq_S2) begin
            side_road = GREEN;
        end
        else if (state_eq_S3) begin
            side_road = YELLOW;
        end
    end
    
    // Sequential logic
    always @(posedge clock) begin
        if (reset) begin
            state <= S0;
            timer <= 0;
        end
        else begin
            state <= next;
            timer <= (state != next) ? 0 : timer + 1;
        end
    end

endmodule