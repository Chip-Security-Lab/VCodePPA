//SystemVerilog
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

    // Pre-register inputs to reduce input-to-register delay
    reg [DATA_W-1:0] measurement_reg;
    reg [DATA_W-1:0] process_noise_reg;
    reg [DATA_W-1:0] measurement_noise_reg;
    
    reg [DATA_W-1:0] prediction;
    reg [DATA_W-1:0] error, next_error;
    reg [DATA_W-1:0] gain, next_gain;
    reg [DATA_W-1:0] next_estimate;
    
    wire [DATA_W-1:0] innovation;
    wire [DATA_W-1:0] innovation_times_gain;
    
    // Register inputs
    always @(posedge clk) begin
        if (reset) begin
            measurement_reg <= 0;
            process_noise_reg <= 0;
            measurement_noise_reg <= 0;
        end else begin
            measurement_reg <= measurement;
            process_noise_reg <= process_noise;
            measurement_noise_reg <= measurement_noise;
        end
    end
    
    // Innovation calculation moved after input registers
    assign innovation = measurement_reg - prediction;
    
    // Pre-compute gain * innovation product
    assign innovation_times_gain = (gain * innovation) >> FRAC_BITS;
    
    // Update prediction and other registers
    always @(posedge clk) begin
        if (reset) begin
            prediction <= 0;
            error <= measurement_noise_reg;
            gain <= 0;
            estimate <= 0;
        end else begin
            prediction <= estimate;
            error <= next_error;
            gain <= next_gain;
            estimate <= next_estimate;
        end
    end
    
    // Combinational logic for next state calculations
    always @(*) begin
        // Calculate next_gain using registered inputs
        next_gain = (error + process_noise_reg << FRAC_BITS) / 
                   (error + process_noise_reg + measurement_noise_reg);
                   
        // Calculate next_estimate
        next_estimate = prediction + innovation_times_gain;
        
        // Calculate next_error
        next_error = ((1 << FRAC_BITS) - gain) * (error + process_noise_reg) >> FRAC_BITS;
    end

endmodule