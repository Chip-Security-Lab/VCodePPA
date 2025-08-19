//SystemVerilog
module traffic_controller(
    input wire clock, reset, car_sensor,
    output reg [1:0] main_road, side_road
);
    localparam GREEN=2'b00, YELLOW=2'b01, RED=2'b10;
    localparam S0=2'b00, S1=2'b01, S2=2'b10, S3=2'b11;
    
    reg [1:0] state_stage1, next_stage1;
    reg [3:0] timer_stage1;
    reg [1:0] state_stage2, next_stage2;
    reg [3:0] timer_stage2;
    reg car_sensor_stage2;
    reg [1:0] state_stage3;
    reg [3:0] timer_stage3;
    
    wire timer_ge_9 = (timer_stage1[3] | (timer_stage1[2] & timer_stage1[0]));
    wire timer_ge_2 = timer_stage1[1];
    wire state_changed = |(state_stage1 ^ next_stage2);
    
    always @(posedge clock) begin
        if (reset) begin
            state_stage1 <= S0;
            timer_stage1 <= 0;
        end else begin
            state_stage1 <= next_stage2;
            timer_stage1 <= state_changed ? 0 : timer_stage1 + 1;
        end
    end
    
    always @(posedge clock) begin
        state_stage2 <= state_stage1;
        timer_stage2 <= timer_stage1;
        car_sensor_stage2 <= car_sensor;
        
        case (state_stage1)
            S0: next_stage2 = (timer_ge_9 & car_sensor) ? S1 : S0;
            S1: next_stage2 = timer_ge_2 ? S2 : S1;
            S2: next_stage2 = timer_ge_9 ? S3 : S2;
            S3: next_stage2 = timer_ge_2 ? S0 : S3;
        endcase
    end
    
    always @(posedge clock) begin
        state_stage3 <= state_stage2;
        timer_stage3 <= timer_stage2;
        
        case (state_stage2)
            S0: {main_road, side_road} = {GREEN, RED};
            S1: {main_road, side_road} = {YELLOW, RED};
            S2: {main_road, side_road} = {RED, GREEN};
            S3: {main_road, side_road} = {RED, YELLOW};
        endcase
    end
endmodule