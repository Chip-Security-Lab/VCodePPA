//SystemVerilog
// SystemVerilog - IEEE 1364-2005 Verilog standard
module hysteresis_recovery (
    input wire sample_clk,
    input wire [9:0] adc_value,
    input wire [9:0] high_threshold,
    input wire [9:0] low_threshold,
    output reg [9:0] clean_signal,
    output reg signal_present
);
    
    // State definition with parameter for readability
    localparam STATE_LOW = 1'b0;
    localparam STATE_HIGH = 1'b1;
    
    // Pipeline stage 1: Comparison signals
    reg above_high_thresh_stage1;
    reg below_low_thresh_stage1;
    reg [9:0] adc_value_stage1;
    reg state;
    
    // Pipeline stage 2: Intermediate values
    reg above_high_thresh_stage2;
    reg below_low_thresh_stage2;
    reg [9:0] adc_value_stage2;
    reg state_stage2;
    
    // Pipeline stage 3: Final calculation inputs
    reg above_high_thresh_stage3;
    reg below_low_thresh_stage3;
    reg [9:0] adc_value_stage3;
    reg state_stage3;
    
    // Pipeline stage 1: Comparison logic
    always @(posedge sample_clk) begin
        above_high_thresh_stage1 <= (adc_value > high_threshold);
        below_low_thresh_stage1 <= (adc_value < low_threshold);
        adc_value_stage1 <= adc_value;
        
        // State transition logic - maintained in stage 1
        case (state)
            STATE_LOW: begin
                if (above_high_thresh_stage1) begin
                    state <= STATE_HIGH;
                end
            end
            
            STATE_HIGH: begin
                if (below_low_thresh_stage1) begin
                    state <= STATE_LOW;
                end
            end
        endcase
    end
    
    // Pipeline stage 2: Forward state and signals
    always @(posedge sample_clk) begin
        above_high_thresh_stage2 <= above_high_thresh_stage1;
        below_low_thresh_stage2 <= below_low_thresh_stage1;
        adc_value_stage2 <= adc_value_stage1;
        state_stage2 <= state;
    end
    
    // Pipeline stage 3: Forward signals to final stage
    always @(posedge sample_clk) begin
        above_high_thresh_stage3 <= above_high_thresh_stage2;
        below_low_thresh_stage3 <= below_low_thresh_stage2;
        adc_value_stage3 <= adc_value_stage2;
        state_stage3 <= state_stage2;
    end
    
    // Pipeline stage 4: Output logic
    always @(posedge sample_clk) begin
        // Signal present determination
        signal_present <= (state_stage3 == STATE_HIGH) || 
                         ((state_stage3 == STATE_LOW) && above_high_thresh_stage3);
                         
        // Clean signal assignment with pipelined signals
        clean_signal <= ((state_stage3 == STATE_HIGH) && !below_low_thresh_stage3) || 
                       ((state_stage3 == STATE_LOW) && above_high_thresh_stage3) ? 
                       adc_value_stage3 : 10'd0;
    end
    
endmodule