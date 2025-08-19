module temp_controller(
    input wire clk,
    input wire reset,
    input wire [7:0] current_temp,
    input wire [7:0] target_temp,
    input wire [1:0] mode, // 00:off, 01:heat, 10:cool, 11:auto
    output reg heater,
    output reg cooler,
    output reg fan,
    output reg [1:0] status // 00:idle, 01:heating, 10:cooling
);
    parameter [1:0] OFF = 2'b00, HEATING = 2'b01, 
                    COOLING = 2'b10, IDLE = 2'b11;
    reg [1:0] state, next_state;
    parameter TEMP_THRESHOLD = 8'd2;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= OFF;
            heater <= 1'b0;
            cooler <= 1'b0;
            fan <= 1'b0;
            status <= 2'b00;
        end else begin
            state <= next_state;
            
            case (state)
                OFF: begin
                    heater <= 1'b0;
                    cooler <= 1'b0;
                    fan <= 1'b0;
                    status <= 2'b00;
                end
                HEATING: begin
                    heater <= 1'b1;
                    cooler <= 1'b0;
                    fan <= 1'b1;
                    status <= 2'b01;
                end
                COOLING: begin
                    heater <= 1'b0;
                    cooler <= 1'b1;
                    fan <= 1'b1;
                    status <= 2'b10;
                end
                IDLE: begin
                    heater <= 1'b0;
                    cooler <= 1'b0;
                    fan <= 1'b0;
                    status <= 2'b00;
                end
            endcase
        end
    end
    
    always @(*) begin
        case (mode)
            2'b00: next_state = OFF;
            2'b01: next_state = (current_temp < target_temp) ? HEATING : IDLE;
            2'b10: next_state = (current_temp > target_temp) ? COOLING : IDLE;
            2'b11: begin
                if (current_temp < target_temp - TEMP_THRESHOLD)
                    next_state = HEATING;
                else if (current_temp > target_temp + TEMP_THRESHOLD)
                    next_state = COOLING;
                else
                    next_state = IDLE;
            end
        endcase
    end
endmodule