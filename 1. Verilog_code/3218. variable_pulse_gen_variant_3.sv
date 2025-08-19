//SystemVerilog
module variable_pulse_gen(
    input CLK,
    input RST,
    input [9:0] PULSE_WIDTH,
    input [9:0] PERIOD,
    output reg PULSE
);
    // Counter stages
    reg [9:0] counter;
    reg [9:0] counter_stage1;
    reg [9:0] counter_stage2;
    reg [9:0] counter_stage3;
    
    // Pipeline control registers
    reg counter_reset_stage1;
    reg counter_reset_stage2;
    
    // Pulse width comparison pipeline stages
    reg comparison_result_stage1;
    reg comparison_result_stage2;
    
    // Input parameters pipeline registers
    reg [9:0] period_stage1;
    reg [9:0] pulse_width_stage1;
    reg [9:0] pulse_width_stage2;
    
    always @(posedge CLK) begin
        if (RST) begin
            // Reset all pipeline stages
            counter <= 10'd0;
            counter_stage1 <= 10'd0;
            counter_stage2 <= 10'd0;
            counter_stage3 <= 10'd0;
            counter_reset_stage1 <= 1'b0;
            counter_reset_stage2 <= 1'b0;
            comparison_result_stage1 <= 1'b0;
            comparison_result_stage2 <= 1'b0;
            period_stage1 <= 10'd0;
            pulse_width_stage1 <= 10'd0;
            pulse_width_stage2 <= 10'd0;
            PULSE <= 1'b0;
        end else begin
            // Pipeline stage for input parameters
            period_stage1 <= PERIOD;
            pulse_width_stage1 <= PULSE_WIDTH;
            pulse_width_stage2 <= pulse_width_stage1;
            
            // Stage 1: Counter increment and period comparison
            if (counter < period_stage1)
                counter <= counter + 10'd1;
            else
                counter <= 10'd0;
                
            counter_reset_stage1 <= (counter >= period_stage1);
            
            // Stage 2: Counter propagation and reset preparation
            counter_stage1 <= counter;
            counter_reset_stage2 <= counter_reset_stage1;
            
            // Stage 3: Counter propagation
            counter_stage2 <= counter_stage1;
            counter_stage3 <= counter_stage2;
            
            // Stage 4: Pulse width comparison (first stage)
            comparison_result_stage1 <= (counter_stage2 < pulse_width_stage1);
            
            // Stage 5: Pulse width comparison (second stage)
            comparison_result_stage2 <= comparison_result_stage1;
            
            // Stage 6: Final output assignment
            PULSE <= comparison_result_stage2;
        end
    end
endmodule