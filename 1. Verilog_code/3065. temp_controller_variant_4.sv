//SystemVerilog
module temp_controller(
    input wire clk, rst_n,
    input wire [7:0] current_temp,
    input wire [7:0] target_temp,
    input wire valid,
    output reg ready,
    output reg heat_on, cool_on, fan_on
);
    localparam IDLE=2'b00, HEATING=2'b01, COOLING=2'b10, FAN_ONLY=2'b11;
    reg [1:0] state_stage1, state_stage2, next_stage1, next_stage2;
    parameter HYSTERESIS = 8'd2;
    reg [7:0] target_temp_reg_stage1, target_temp_reg_stage2;
    reg [7:0] current_temp_stage1, current_temp_stage2;
    reg valid_stage1, valid_stage2;
    reg ready_stage1, ready_stage2;
    
    // Stage 1: Input registration and state transition
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state_stage1 <= IDLE;
            target_temp_reg_stage1 <= 8'd0;
            current_temp_stage1 <= 8'd0;
            valid_stage1 <= 1'b0;
            ready_stage1 <= 1'b0;
        end
        else begin
            state_stage1 <= next_stage1;
            current_temp_stage1 <= current_temp;
            valid_stage1 <= valid;
            ready_stage1 <= (state_stage1 == IDLE) || (state_stage1 == FAN_ONLY);
            if (valid_stage1 && ready_stage1) begin
                target_temp_reg_stage1 <= target_temp;
            end
        end
    
    // Stage 2: State machine and output generation
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state_stage2 <= IDLE;
            target_temp_reg_stage2 <= 8'd0;
            current_temp_stage2 <= 8'd0;
            valid_stage2 <= 1'b0;
            ready_stage2 <= 1'b0;
            heat_on <= 1'b0;
            cool_on <= 1'b0;
            fan_on <= 1'b0;
        end
        else begin
            state_stage2 <= state_stage1;
            target_temp_reg_stage2 <= target_temp_reg_stage1;
            current_temp_stage2 <= current_temp_stage1;
            valid_stage2 <= valid_stage1;
            ready_stage2 <= ready_stage1;
            
            case (state_stage2)
                IDLE: begin
                    if (current_temp_stage2 < target_temp_reg_stage2 - HYSTERESIS)
                        next_stage2 = HEATING;
                    else if (current_temp_stage2 > target_temp_reg_stage2 + HYSTERESIS)
                        next_stage2 = COOLING;
                    else
                        next_stage2 = IDLE;
                end
                HEATING: begin
                    heat_on = 1'b1;
                    fan_on = 1'b1;
                    if (current_temp_stage2 >= target_temp_reg_stage2)
                        next_stage2 = FAN_ONLY;
                    else
                        next_stage2 = HEATING;
                end
                COOLING: begin
                    cool_on = 1'b1;
                    fan_on = 1'b1;
                    if (current_temp_stage2 <= target_temp_reg_stage2)
                        next_stage2 = FAN_ONLY;
                    else
                        next_stage2 = COOLING;
                end
                FAN_ONLY: begin
                    fan_on = 1'b1;
                    if (current_temp_stage2 < target_temp_reg_stage2 - HYSTERESIS)
                        next_stage2 = HEATING;
                    else if (current_temp_stage2 > target_temp_reg_stage2 + HYSTERESIS)
                        next_stage2 = COOLING;
                    else if ((state_stage2 == FAN_ONLY) && 
                            (current_temp_stage2 >= target_temp_reg_stage2 - HYSTERESIS) && 
                            (current_temp_stage2 <= target_temp_reg_stage2 + HYSTERESIS))
                        next_stage2 = IDLE;
                    else
                        next_stage2 = FAN_ONLY;
                end
            endcase
        end
    
    // Stage 1 next state logic
    always @(*) begin
        next_stage1 = next_stage2;
    end
    
    // Output assignments
    assign ready = ready_stage2;
endmodule