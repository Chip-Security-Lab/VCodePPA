//SystemVerilog
module hysteresis_recovery (
    input wire sample_clk,
    input wire [9:0] adc_value,
    input wire [9:0] high_threshold,
    input wire [9:0] low_threshold,
    output reg [9:0] clean_signal,
    output reg signal_present
);
    // Main state register
    reg state;
    
    // Buffered registers for high fan-out signals
    reg [9:0] adc_value_buf1, adc_value_buf2;
    reg state_buf1, state_buf2;
    
    // Register input ADC value to reduce fan-out load
    always @(posedge sample_clk) begin
        adc_value_buf1 <= adc_value;
        adc_value_buf2 <= adc_value_buf1;
    end
    
    // Buffer the state signal to reduce fan-out
    always @(posedge sample_clk) begin
        state_buf1 <= state;
        state_buf2 <= state_buf1;
    end
    
    // Main state machine logic with optimized signal usage
    always @(posedge sample_clk) begin
        if (state_buf1 == 1'b0 && adc_value_buf1 > high_threshold) begin
            state <= 1'b1;
            signal_present <= 1'b1;
            clean_signal <= adc_value_buf2;
        end else if (state_buf1 == 1'b1 && adc_value_buf1 < low_threshold) begin
            state <= 1'b0;
            signal_present <= 1'b0;
            clean_signal <= 10'd0;
        end else if (state_buf1 == 1'b1) begin
            clean_signal <= adc_value_buf2;
        end else begin
            clean_signal <= 10'd0;
        end
    end
endmodule