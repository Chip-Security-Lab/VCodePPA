//SystemVerilog
module pwm_timer (
    input clk, rst, enable,
    input [15:0] period, duty,
    output reg pwm_out
);
    // Stage 1: Counter logic
    reg [15:0] counter_stage1;
    reg valid_stage1;
    reg [15:0] period_stage1, duty_stage1;
    
    // Stage 2: Comparison and output logic
    reg [15:0] counter_stage2;
    reg valid_stage2;
    reg [15:0] duty_stage2;
    
    // Stage 1: Counter management and period check
    always @(posedge clk) begin
        case ({rst, enable})
            2'b10, 2'b11: begin // Reset takes priority
                counter_stage1 <= 16'd0;
                valid_stage1 <= 1'b0;
                period_stage1 <= 16'd0;
                duty_stage1 <= 16'd0;
            end
            2'b01: begin // Enable active, no reset
                valid_stage1 <= 1'b1;
                period_stage1 <= period;
                duty_stage1 <= duty;
                
                counter_stage1 <= (counter_stage1 >= period - 1) ? 16'd0 : counter_stage1 + 16'd1;
            end
            2'b00: begin // Neither reset nor enable
                valid_stage1 <= 1'b0;
                // Keep other values unchanged
            end
        endcase
    end
    
    // Stage 2: Comparison and output generation
    always @(posedge clk) begin
        case ({rst, valid_stage2 && enable})
            2'b10, 2'b11: begin // Reset takes priority
                counter_stage2 <= 16'd0;
                valid_stage2 <= 1'b0;
                duty_stage2 <= 16'd0;
                pwm_out <= 1'b0;
            end
            2'b01: begin // Enable and valid, no reset
                counter_stage2 <= counter_stage1;
                valid_stage2 <= valid_stage1;
                duty_stage2 <= duty_stage1;
                pwm_out <= (counter_stage2 < duty_stage2);
            end
            2'b00: begin // Neither reset nor (valid and enable)
                counter_stage2 <= counter_stage1;
                valid_stage2 <= valid_stage1;
                duty_stage2 <= duty_stage1;
                // Keep pwm_out unchanged
            end
        endcase
    end
endmodule