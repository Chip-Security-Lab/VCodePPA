//SystemVerilog
module temp_controller(
    input wire clk, rst_n,
    input wire [7:0] current_temp,
    input wire [7:0] target_temp,
    output reg heat_on, cool_on, fan_on
);
    localparam IDLE=2'b00, HEATING=2'b01, COOLING=2'b10, FAN_ONLY=2'b11;
    reg [1:0] state_stage1, state_stage2, next_stage1;
    parameter HYSTERESIS = 8'd2;
    
    // Carry-save adder signals
    wire [7:0] temp_diff;
    wire [7:0] temp_sum;
    wire [7:0] temp_upper;
    wire [7:0] temp_lower;
    wire [7:0] carry;
    
    // Carry-save adder implementation
    assign temp_upper = target_temp + HYSTERESIS;
    assign temp_lower = target_temp - HYSTERESIS;
    
    // Generate carry bits
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : carry_gen
            if (i == 0)
                assign carry[i] = 1'b0;
            else
                assign carry[i] = (current_temp[i-1] & temp_upper[i-1]) | 
                                (current_temp[i-1] & carry[i-1]) | 
                                (temp_upper[i-1] & carry[i-1]);
        end
    endgenerate
    
    // Sum calculation
    assign temp_sum = current_temp ^ temp_upper ^ carry;
    
    // Temperature comparison logic
    wire temp_above_upper = |(temp_sum & 8'h80);
    wire temp_below_lower = |((~temp_sum) & 8'h80);
    
    // Pipeline stage 1: State transition logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            state_stage2 <= IDLE;
        end else begin
            state_stage1 <= next_stage1;
            state_stage2 <= state_stage1;
        end
    end
    
    // Pipeline stage 1: Next state computation
    always @(*) begin
        case (state_stage1)
            IDLE: begin
                if (temp_below_lower)
                    next_stage1 = HEATING;
                else if (temp_above_upper)
                    next_stage1 = COOLING;
                else
                    next_stage1 = IDLE;
            end
            HEATING: begin
                if (!temp_below_lower)
                    next_stage1 = FAN_ONLY;
                else
                    next_stage1 = HEATING;
            end
            COOLING: begin
                if (!temp_above_upper)
                    next_stage1 = FAN_ONLY;
                else
                    next_stage1 = COOLING;
            end
            FAN_ONLY: begin
                if (temp_below_lower)
                    next_stage1 = HEATING;
                else if (temp_above_upper)
                    next_stage1 = COOLING;
                else if ((state_stage1 == FAN_ONLY) && 
                        (!temp_below_lower) && 
                        (!temp_above_upper))
                    next_stage1 = IDLE;
                else
                    next_stage1 = FAN_ONLY;
            end
        endcase
    end
    
    // Pipeline stage 2: Output generation
    always @(*) begin
        heat_on = 1'b0;
        cool_on = 1'b0;
        fan_on = 1'b0;
        
        case (state_stage2)
            HEATING: begin
                heat_on = 1'b1;
                fan_on = 1'b1;
            end
            COOLING: begin
                cool_on = 1'b1;
                fan_on = 1'b1;
            end
            FAN_ONLY: begin
                fan_on = 1'b1;
            end
            default: begin
                heat_on = 1'b0;
                cool_on = 1'b0;
                fan_on = 1'b0;
            end
        endcase
    end
endmodule