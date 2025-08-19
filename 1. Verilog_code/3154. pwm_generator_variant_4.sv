//SystemVerilog
module pwm_generator(
    input clk,
    input rst,
    input [7:0] duty_cycle,
    output reg pwm_out
);
    // Pipeline registers
    reg [7:0] counter_stage1;
    reg [7:0] duty_cycle_stage1;
    reg [7:0] duty_cycle_stage2;
    reg compare_result_stage2;
    
    // Stage 1: Counter increment and register duty cycle
    always @(posedge clk) begin
        if (rst) begin
            counter_stage1 <= 8'h00;
            duty_cycle_stage1 <= 8'h00;
        end else begin
            counter_stage1 <= counter_stage1 + 1'b1;
            duty_cycle_stage1 <= duty_cycle;
        end
    end
    
    // Stage 2: Compare counter with duty cycle
    always @(posedge clk) begin
        if (rst) begin
            duty_cycle_stage2 <= 8'h00;
            compare_result_stage2 <= 1'b0;
        end else begin
            duty_cycle_stage2 <= duty_cycle_stage1;
            compare_result_stage2 <= (counter_stage1 < duty_cycle_stage1) ? 1'b1 : 1'b0;
        end
    end
    
    // Stage 3: Output stage
    always @(posedge clk) begin
        if (rst) begin
            pwm_out <= 1'b0;
        end else begin
            pwm_out <= compare_result_stage2;
        end
    end
endmodule