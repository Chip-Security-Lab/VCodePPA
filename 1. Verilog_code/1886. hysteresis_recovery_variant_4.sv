//SystemVerilog
module hysteresis_recovery (
    input wire sample_clk,
    input wire [9:0] adc_value,
    input wire [9:0] high_threshold,
    input wire [9:0] low_threshold,
    output reg [9:0] clean_signal,
    output reg signal_present
);
    // State definitions
    localparam STATE_LOW = 1'b0;
    localparam STATE_HIGH = 1'b1;
    
    reg state;
    
    // Optimized state transition and output logic combined
    always @(posedge sample_clk) begin
        case (state)
            STATE_LOW: begin
                if (adc_value >= high_threshold) begin
                    state <= STATE_HIGH;
                    signal_present <= 1'b1;
                    clean_signal <= adc_value;
                end else begin
                    // State remains LOW
                    clean_signal <= 10'd0;
                    // Signal present remains unchanged
                end
            end
            
            STATE_HIGH: begin
                if (adc_value <= low_threshold) begin
                    state <= STATE_LOW;
                    signal_present <= 1'b0;
                    clean_signal <= 10'd0;
                end else begin
                    // State remains HIGH
                    clean_signal <= adc_value;
                    // Signal present remains unchanged
                end
            end
        endcase
    end
    
    // Initial values
    initial begin
        state = STATE_LOW;
        signal_present = 1'b0;
        clean_signal = 10'd0;
    end
    
endmodule