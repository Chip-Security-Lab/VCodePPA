//SystemVerilog
module pwm_dead_time(
    input clk,
    input rst,
    input [7:0] duty,
    input [3:0] dead_time,
    output reg pwm_high,
    output reg pwm_low
);
    // Pipeline stage registers
    reg [7:0] counter;
    reg [7:0] duty_stage1;
    reg [3:0] dead_time_stage1;
    reg [7:0] duty_stage2;
    reg [7:0] dead_threshold_stage2;
    
    // Pipeline stage 1: Input registration and counter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 8'd0;
            duty_stage1 <= 8'd0;
            dead_time_stage1 <= 4'd0;
        end else begin
            counter <= counter + 8'd1;
            duty_stage1 <= duty;
            dead_time_stage1 <= dead_time;
        end
    end
    
    // Pipeline stage 2: Threshold calculation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            duty_stage2 <= 8'd0;
            dead_threshold_stage2 <= 8'd0;
        end else begin
            duty_stage2 <= duty_stage1;
            dead_threshold_stage2 <= duty_stage1 + {4'd0, dead_time_stage1};
        end
    end
    
    // Pipeline stage 3: Output generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pwm_high <= 1'b0;
            pwm_low <= 1'b0;
        end else begin
            pwm_high <= (counter < duty_stage2);
            pwm_low <= (counter > dead_threshold_stage2);
        end
    end
endmodule