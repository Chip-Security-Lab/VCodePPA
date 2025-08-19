//SystemVerilog
module pwm_generator(
    input clk,
    input rst,
    input [7:0] duty_cycle,
    output reg pwm_out
);
    // Pipeline stage 1 - Counter
    reg [7:0] counter_stage1;
    reg [7:0] duty_cycle_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 - Comparison
    reg comparison_result_stage2;
    reg valid_stage2;
    
    // Stage 1: Counter increment and duty cycle register
    always @(posedge clk) begin
        if (rst) begin
            counter_stage1 <= 8'h00;
            duty_cycle_stage1 <= 8'h00;
            valid_stage1 <= 1'b0;
        end else begin
            counter_stage1 <= counter_stage1 + 1'b1;
            duty_cycle_stage1 <= duty_cycle;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Compare counter with duty cycle
    always @(posedge clk) begin
        if (rst) begin
            comparison_result_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            comparison_result_stage2 <= (counter_stage1 < duty_cycle_stage1) ? 1'b1 : 1'b0;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk) begin
        if (rst) begin
            pwm_out <= 1'b0;
        end else if (valid_stage2) begin
            pwm_out <= comparison_result_stage2;
        end
    end
endmodule