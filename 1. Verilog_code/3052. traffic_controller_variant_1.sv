//SystemVerilog
module traffic_controller(
    input wire clock, reset, car_sensor,
    output reg [1:0] main_road, side_road
);
    localparam GREEN=2'b00, YELLOW=2'b01, RED=2'b10;
    localparam S0=2'b00, S1=2'b01, S2=2'b10, S3=2'b11;
    reg [1:0] state, next_state, next_state_pipe;
    reg [3:0] timer, next_timer;
    reg [1:0] main_road_next, side_road_next;
    
    // Baugh-Wooley multiplier for timer comparison
    wire [3:0] timer_comp;
    wire [3:0] timer_comp_inv;
    wire [3:0] timer_comp_result;
    
    assign timer_comp = timer;
    assign timer_comp_inv = ~timer_comp;
    
    // Baugh-Wooley multiplication for timer comparison
    assign timer_comp_result[0] = timer_comp[0] & timer_comp_inv[0];
    assign timer_comp_result[1] = (timer_comp[1] & timer_comp_inv[1]) ^ 
                                 (timer_comp[0] & timer_comp_inv[1]) ^ 
                                 (timer_comp[1] & timer_comp_inv[0]);
    assign timer_comp_result[2] = (timer_comp[2] & timer_comp_inv[2]) ^ 
                                 (timer_comp[1] & timer_comp_inv[2]) ^ 
                                 (timer_comp[2] & timer_comp_inv[1]);
    assign timer_comp_result[3] = (timer_comp[3] & timer_comp_inv[3]) ^ 
                                 (timer_comp[2] & timer_comp_inv[3]) ^ 
                                 (timer_comp[3] & timer_comp_inv[2]);
    
    // Pipeline stage 1: State transition logic with Baugh-Wooley comparison
    always @(*) begin
        case (state)
            S0: next_state = (timer_comp_result >= 9 && car_sensor) ? S1 : S0;
            S1: next_state = (timer_comp_result >= 2) ? S2 : S1;
            S2: next_state = (timer_comp_result >= 9) ? S3 : S2;
            S3: next_state = (timer_comp_result >= 2) ? S0 : S3;
        endcase
    end
    
    // Pipeline stage 2: Timer and state update
    always @(posedge clock) begin
        if (reset) begin
            state <= S0;
            timer <= 0;
            next_state_pipe <= S0;
        end else begin
            state <= next_state_pipe;
            next_state_pipe <= next_state;
            timer <= (state != next_state_pipe) ? 0 : timer + 1;
        end
    end
    
    // Pipeline stage 3: Output generation
    always @(*) begin
        case (state)
            S0: begin main_road_next = GREEN; side_road_next = RED; end
            S1: begin main_road_next = YELLOW; side_road_next = RED; end
            S2: begin main_road_next = RED; side_road_next = GREEN; end
            S3: begin main_road_next = RED; side_road_next = YELLOW; end
        endcase
    end
    
    // Output register
    always @(posedge clock) begin
        if (reset) begin
            main_road <= RED;
            side_road <= RED;
        end else begin
            main_road <= main_road_next;
            side_road <= side_road_next;
        end
    end
endmodule