//SystemVerilog
module duty_cycle_clock_gate (
    input  wire clk_in,
    input  wire rst_n,
    input  wire [2:0] duty_ratio,
    output wire clk_out
);
    reg [2:0] phase;
    reg [2:0] duty_ratio_reg;
    reg phase_compare_result;
    
    // Register duty_ratio input to break potential critical path
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            duty_ratio_reg <= 3'd0;
        else
            duty_ratio_reg <= duty_ratio;
    end
    
    // Phase counter logic
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            phase <= 3'd0;
        else
            phase <= (phase == 3'd7) ? 3'd0 : phase + 1'b1;
    end
    
    // Optimized comparison logic with range check
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            phase_compare_result <= 1'b0;
        else begin
            // Special cases for common duty ratios for faster implementation
            case (duty_ratio_reg)
                3'd0: phase_compare_result <= 1'b0; // 0% duty cycle
                3'd7: phase_compare_result <= 1'b1; // 100% duty cycle (7/8)
                default: phase_compare_result <= (phase < duty_ratio_reg);
            endcase
        end
    end
    
    // Final gated clock output
    assign clk_out = clk_in & phase_compare_result;
endmodule