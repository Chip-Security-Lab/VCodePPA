module sync_kalman_filter #(
    parameter DATA_W = 16,
    parameter FRAC_BITS = 8
)(
    input clk, reset,
    input [DATA_W-1:0] measurement,
    input [DATA_W-1:0] process_noise,
    input [DATA_W-1:0] measurement_noise,
    output reg [DATA_W-1:0] estimate
);
    reg [DATA_W-1:0] prediction, error, gain;
    wire [DATA_W-1:0] innovation;
    
    // Innovation is difference between measurement and prediction
    assign innovation = measurement - prediction;
    
    always @(posedge clk) begin
        if (reset) begin
            prediction <= 0;
            estimate <= 0;
            error <= measurement_noise;
            gain <= 0;
        end else begin
            // Prediction step (simplified)
            prediction <= estimate;
            error <= error + process_noise;
            
            // Update step
            gain <= (error << FRAC_BITS) / (error + measurement_noise);
            estimate <= prediction + ((gain * innovation) >> FRAC_BITS);
            error <= ((1 << FRAC_BITS) - gain) * error >> FRAC_BITS;
        end
    end
endmodule