module traffic_controller(
    input wire clock, reset, car_sensor,
    output reg [1:0] main_road, side_road
);
    localparam GREEN=2'b00, YELLOW=2'b01, RED=2'b10;
    localparam S0=2'b00, S1=2'b01, S2=2'b10, S3=2'b11;
    reg [1:0] state, next;
    reg [3:0] timer;
    
    always @(posedge clock)
        if (reset) begin state <= S0; timer <= 0; end
        else begin state <= next; timer <= (state != next) ? 0 : timer + 1; end
    
    always @(*) begin
        case (state)
            S0: next = (timer >= 9 && car_sensor) ? S1 : S0;
            S1: next = (timer >= 2) ? S2 : S1;
            S2: next = (timer >= 9) ? S3 : S2;
            S3: next = (timer >= 2) ? S0 : S3;
        endcase
        
        case (state)
            S0: begin main_road = GREEN; side_road = RED; end
            S1: begin main_road = YELLOW; side_road = RED; end
            S2: begin main_road = RED; side_road = GREEN; end
            S3: begin main_road = RED; side_road = YELLOW; end
        endcase
    end
endmodule