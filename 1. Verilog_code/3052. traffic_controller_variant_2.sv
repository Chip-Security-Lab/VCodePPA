//SystemVerilog
module traffic_controller(
    input wire clock, reset, car_sensor,
    output reg [1:0] main_road, side_road
);
    localparam GREEN=2'b00, YELLOW=2'b01, RED=2'b10;
    localparam S0=2'b00, S1=2'b01, S2=2'b10, S3=2'b11;
    
    // Pipeline stage 1 registers
    reg [1:0] state_stage1, next_state_stage1;
    reg [3:0] timer_stage1;
    reg car_sensor_stage1;
    
    // Pipeline stage 2 registers
    reg [1:0] state_stage2, next_state_stage2;
    reg [3:0] timer_stage2;
    reg car_sensor_stage2;
    
    // Stage 1: Input sampling, timer update and state transition logic
    always @(posedge clock) begin
        if (reset) begin
            state_stage1 <= S0;
            timer_stage1 <= 0;
            car_sensor_stage1 <= 0;
        end else begin
            car_sensor_stage1 <= car_sensor;
            state_stage1 <= state_stage2;
            timer_stage1 <= timer_stage2;
        end
    end
    
    // Stage 2: Next state computation and output generation
    always @(posedge clock) begin
        state_stage2 <= state_stage1;
        car_sensor_stage2 <= car_sensor_stage1;
        
        if (state_stage1 != next_state_stage1) begin
            timer_stage2 <= 0;
        end else begin
            timer_stage2 <= timer_stage1 + 1;
        end
        
        case (state_stage1)
            S0: begin 
                next_state_stage2 = (timer_stage1 >= 9 && car_sensor_stage1) ? S1 : S0;
                main_road <= GREEN; 
                side_road <= RED; 
            end
            S1: begin 
                next_state_stage2 = (timer_stage1 >= 2) ? S2 : S1;
                main_road <= YELLOW; 
                side_road <= RED; 
            end
            S2: begin 
                next_state_stage2 = (timer_stage1 >= 9) ? S3 : S2;
                main_road <= RED; 
                side_road <= GREEN; 
            end
            S3: begin 
                next_state_stage2 = (timer_stage1 >= 2) ? S0 : S3;
                main_road <= RED; 
                side_road <= YELLOW; 
            end
            default: begin 
                next_state_stage2 = S0;
                main_road <= RED; 
                side_road <= RED; 
            end
        endcase
    end
endmodule