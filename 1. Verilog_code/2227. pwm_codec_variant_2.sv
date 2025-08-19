//SystemVerilog IEEE 1364-2005
module pwm_codec (
    input wire clk, rst_n, 
    input wire [7:0] duty_in,    // For encoding
    input wire pwm_in,           // For decoding
    output reg pwm_out,          // Encoded PWM signal
    output reg [7:0] duty_out,   // Decoded duty cycle
    output wire valid_duty       // Valid decoded value
);
    // Encoder registers
    reg [7:0] counter_enc;
    reg [7:0] duty_in_reg;
    reg pwm_stage;
    
    // Decoder registers
    reg pwm_in_reg, pwm_in_prev;
    reg [7:0] counter_dec;
    reg pulse_active;
    reg [7:0] pulse_start_counter;
    reg [7:0] pulse_width;
    reg valid_width;
    
    // Output assignment for decoder valid signal
    assign valid_duty = valid_width;
    
    // Optimized encoder logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_enc <= 8'h00;
            duty_in_reg <= 8'h00;
            pwm_stage <= 1'b0;
            pwm_out <= 1'b0;
        end else begin
            // Increment counter in each cycle
            counter_enc <= counter_enc + 8'h01;
            
            // Register duty input (moved forward)
            duty_in_reg <= duty_in;
            
            // Generate PWM signal based on comparison
            pwm_stage <= (counter_enc < duty_in_reg) ? 1'b1 : 1'b0;
            
            // Register the output
            pwm_out <= pwm_stage;
        end
    end
    
    // Optimized decoder logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_in_reg <= 1'b0;
            pwm_in_prev <= 1'b0;
            counter_dec <= 8'h00;
            pulse_active <= 1'b0;
            pulse_start_counter <= 8'h00;
            pulse_width <= 8'h00;
            valid_width <= 1'b0;
            duty_out <= 8'h00;
        end else begin
            // Register input signals immediately (moved forward)
            pwm_in_prev <= pwm_in_reg;
            pwm_in_reg <= pwm_in;
            
            // Increment decoder counter
            counter_dec <= counter_dec + 8'h01;
            
            // Default valid flag state
            valid_width <= 1'b0;
            
            // Pulse detection with registered signals
            if (pwm_in_reg && !pwm_in_prev) begin
                // Rising edge detected
                pulse_active <= 1'b1;
                pulse_start_counter <= counter_dec;
            end
            
            if (!pwm_in_reg && pwm_in_prev && pulse_active) begin
                // Falling edge detected - calculate width
                pulse_width <= counter_dec - pulse_start_counter;
                pulse_active <= 1'b0;
                valid_width <= 1'b1;
            end
            
            // Update the output duty cycle when valid
            if (valid_width) begin
                duty_out <= pulse_width;
            end
        end
    end
endmodule