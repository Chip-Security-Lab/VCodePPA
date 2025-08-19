module hysteresis_recovery (
    input wire sample_clk,
    input wire [9:0] adc_value,
    input wire [9:0] high_threshold,
    input wire [9:0] low_threshold,
    output reg [9:0] clean_signal,
    output reg signal_present
);
    reg state;
    
    always @(posedge sample_clk) begin
        case (state)
            1'b0: begin // Low state
                if (adc_value > high_threshold) begin
                    state <= 1'b1;
                    signal_present <= 1'b1;
                    clean_signal <= adc_value;
                end else begin
                    clean_signal <= 10'd0;
                end
            end
            1'b1: begin // High state
                if (adc_value < low_threshold) begin
                    state <= 1'b0;
                    signal_present <= 1'b0;
                    clean_signal <= 10'd0;
                end else begin
                    clean_signal <= adc_value;
                end
            end
        endcase
    end
endmodule