//SystemVerilog
module pwm_codec (
    input wire clk, rst_n, 
    input wire [7:0] duty_in,    // For encoding
    input wire pwm_in,           // For decoding
    output reg pwm_out,          // Encoded PWM signal
    output reg [7:0] duty_out,   // Decoded duty cycle
    output wire valid_duty       // Valid decoded value
);
    // PWM period counter
    reg [7:0] counter;
    reg [7:0] capture;
    reg rising_detected, pulse_active;
    
    // Edge detection signals
    reg pwm_in_prev, pwm_in_ff;
    wire rising_edge;
    wire falling_edge;
    
    // Registered duty_in to push registers forward
    reg [7:0] duty_in_ff;
    
    // Pre-compute edge detection
    assign rising_edge = pwm_in_ff & ~pwm_in_prev;
    assign falling_edge = ~pwm_in_ff & pwm_in_prev;
    assign valid_duty = rising_detected;
    
    // Register input signals to push registers forward through combinational logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_in_ff <= 1'b0;
            duty_in_ff <= 8'h00;
        end else begin
            pwm_in_ff <= pwm_in;
            duty_in_ff <= duty_in;
        end
    end
    
    // PWM encoder with balanced paths
    // Pre-compute counter comparison moved into sequential block
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'h00;
            pwm_out <= 1'b0;
        end else begin
            counter <= counter + 8'h01;
            pwm_out <= (counter < duty_in_ff); // Compare with registered input
        end
    end
    
    // Edge detection register - now using the registered input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_in_prev <= 1'b0;
        end else begin
            pwm_in_prev <= pwm_in_ff;
        end
    end
    
    // PWM decoder (measures duty cycle)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            capture <= 8'h00;
            duty_out <= 8'h00;
            rising_detected <= 1'b0;
            pulse_active <= 1'b0;
        end else begin
            // Rising edge detection
            if (rising_edge) begin
                capture <= 8'h00;
                duty_out <= capture;
                rising_detected <= 1'b1;
                pulse_active <= 1'b1;
            // Falling edge detection
            end else if (falling_edge) begin
                pulse_active <= 1'b0;
                rising_detected <= 1'b0;
            // Counter operation
            end else begin
                rising_detected <= 1'b0;
                if (pulse_active) begin
                    capture <= capture + 8'h01;
                end
            end
        end
    end
endmodule