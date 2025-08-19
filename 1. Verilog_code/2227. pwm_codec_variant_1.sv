//SystemVerilog - IEEE 1364-2005
module pwm_codec (
    input wire clk, rst_n,
    // Input interface - encoding path
    input wire [7:0] duty_in,    // For encoding
    input wire duty_in_valid,    // Indicates duty_in is valid
    output wire duty_in_ready,   // Indicates module is ready for new duty_in
    
    // Input interface - decoding path
    input wire pwm_in,           // For decoding
    input wire pwm_in_valid,     // Indicates pwm_in is valid
    output wire pwm_in_ready,    // Indicates module is ready for new pwm_in
    
    // Output interface - encoding path
    output reg pwm_out,          // Encoded PWM signal
    output reg pwm_out_valid,    // Indicates pwm_out is valid
    input wire pwm_out_ready,    // Downstream component is ready to accept pwm_out
    
    // Output interface - decoding path
    output reg [7:0] duty_out,   // Decoded duty cycle
    output reg duty_out_valid,   // Indicates duty_out is valid
    input wire duty_out_ready    // Downstream component is ready to accept duty_out
);
    // PWM period counter pipeline stages
    reg [3:0] counter_low_stage1, counter_low_stage2;
    reg [3:0] counter_high_stage1, counter_high_stage2;
    reg [7:0] counter_combined_stage3;
    
    // PWM encoder pipeline registers
    reg [7:0] duty_in_stage1, duty_in_stage2, duty_in_stage3;
    reg busy_encoding_stage1, busy_encoding_stage2, busy_encoding_stage3;
    reg compare_result_stage3, compare_result_stage4;
    
    // PWM decoder pipeline stages
    reg [3:0] capture_low_stage1, capture_low_stage2;
    reg [3:0] capture_high_stage1, capture_high_stage2;
    reg [7:0] capture_combined_stage3;
    reg rising_detected_stage1, rising_detected_stage2, rising_detected_stage3;
    reg pulse_active_stage1, pulse_active_stage2, pulse_active_stage3;
    reg busy_decoding_stage1, busy_decoding_stage2, busy_decoding_stage3;
    
    // PWM signal pipeline
    reg pwm_in_reg_stage1, pwm_in_reg_stage2;
    reg pwm_in_prev_stage1, pwm_in_prev_stage2;
    
    // Output stage registers
    reg pwm_ready_to_clear;
    reg duty_ready_to_clear;
    
    // Ready signals generation
    assign duty_in_ready = !busy_encoding_stage1;
    assign pwm_in_ready = !busy_decoding_stage1;
    
    // PWM encoder pipeline - Stage 1: Input capture and counter low bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_low_stage1 <= 4'h0;
            counter_high_stage1 <= 4'h0;
            duty_in_stage1 <= 8'h00;
            busy_encoding_stage1 <= 1'b0;
        end else begin
            // Accept new duty cycle when ready and valid
            if (duty_in_valid && duty_in_ready) begin
                duty_in_stage1 <= duty_in;
                busy_encoding_stage1 <= 1'b1;
            end else if (counter_low_stage1 == 4'hF && counter_high_stage1 == 4'hF) begin
                busy_encoding_stage1 <= 1'b0;
            end
            
            // Counter low nibble increment
            counter_low_stage1 <= counter_low_stage1 + 4'h1;
            
            // Increment high nibble when low nibble overflows
            if (counter_low_stage1 == 4'hF) begin
                counter_high_stage1 <= counter_high_stage1 + 4'h1;
            end
        end
    end
    
    // PWM encoder pipeline - Stage 2: Counter propagation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_low_stage2 <= 4'h0;
            counter_high_stage2 <= 4'h0;
            duty_in_stage2 <= 8'h00;
            busy_encoding_stage2 <= 1'b0;
        end else begin
            counter_low_stage2 <= counter_low_stage1;
            counter_high_stage2 <= counter_high_stage1;
            duty_in_stage2 <= duty_in_stage1;
            busy_encoding_stage2 <= busy_encoding_stage1;
        end
    end
    
    // PWM encoder pipeline - Stage 3: Combine counter and compare
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_combined_stage3 <= 8'h00;
            duty_in_stage3 <= 8'h00;
            busy_encoding_stage3 <= 1'b0;
            compare_result_stage3 <= 1'b0;
        end else begin
            counter_combined_stage3 <= {counter_high_stage2, counter_low_stage2};
            duty_in_stage3 <= duty_in_stage2;
            busy_encoding_stage3 <= busy_encoding_stage2;
            
            // Comparison operation
            if (busy_encoding_stage2) begin
                compare_result_stage3 <= ({counter_high_stage2, counter_low_stage2} < duty_in_stage2) ? 1'b1 : 1'b0;
            end else begin
                compare_result_stage3 <= 1'b0;
            end
        end
    end
    
    // PWM encoder pipeline - Stage 4: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_out <= 1'b0;
            pwm_out_valid <= 1'b0;
            compare_result_stage4 <= 1'b0;
            pwm_ready_to_clear <= 1'b0;
        end else begin
            compare_result_stage4 <= compare_result_stage3;
            
            if (busy_encoding_stage3) begin
                pwm_out <= compare_result_stage3;
                if (!pwm_out_valid) begin
                    pwm_out_valid <= 1'b1;
                end
            end
            
            // Handle handshaking
            if (pwm_out_valid && pwm_out_ready) begin
                pwm_ready_to_clear <= 1'b1;
            end
            
            if (pwm_ready_to_clear) begin
                pwm_out_valid <= 1'b0;
                pwm_ready_to_clear <= 1'b0;
            end
        end
    end
    
    // PWM decoder pipeline - Stage 1: Edge detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_in_reg_stage1 <= 1'b0;
            pwm_in_prev_stage1 <= 1'b0;
            rising_detected_stage1 <= 1'b0;
            pulse_active_stage1 <= 1'b0;
            busy_decoding_stage1 <= 1'b0;
            capture_low_stage1 <= 4'h0;
            capture_high_stage1 <= 4'h0;
        end else begin
            // Sample input
            pwm_in_reg_stage1 <= pwm_in;
            pwm_in_prev_stage1 <= pwm_in_reg_stage1;
            
            // Accept new PWM input when ready and valid
            if (pwm_in_valid && pwm_in_ready) begin
                busy_decoding_stage1 <= 1'b1;
                
                // Rising edge detection
                if (pwm_in_reg_stage1 && !pwm_in_prev_stage1) begin
                    rising_detected_stage1 <= 1'b1;
                    pulse_active_stage1 <= 1'b1;
                    capture_low_stage1 <= 4'h0;
                    capture_high_stage1 <= 4'h0;
                end
                
                // Falling edge detection
                if (!pwm_in_reg_stage1 && pwm_in_prev_stage1 && pulse_active_stage1) begin
                    pulse_active_stage1 <= 1'b0;
                end
                
                // Counter for pulse width measurement
                if (pulse_active_stage1) begin
                    capture_low_stage1 <= capture_low_stage1 + 4'h1;
                    if (capture_low_stage1 == 4'hF) begin
                        capture_high_stage1 <= capture_high_stage1 + 4'h1;
                    end
                end
                
                // Complete decoding when full cycle detected
                if (rising_detected_stage1 && pwm_in_reg_stage1 && !pwm_in_prev_stage1) begin
                    busy_decoding_stage1 <= 1'b0;
                end
            end
        end
    end
    
    // PWM decoder pipeline - Stage 2: Capture propagation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            capture_low_stage2 <= 4'h0;
            capture_high_stage2 <= 4'h0;
            rising_detected_stage2 <= 1'b0;
            pulse_active_stage2 <= 1'b0;
            busy_decoding_stage2 <= 1'b0;
            pwm_in_reg_stage2 <= 1'b0;
            pwm_in_prev_stage2 <= 1'b0;
        end else begin
            capture_low_stage2 <= capture_low_stage1;
            capture_high_stage2 <= capture_high_stage1;
            rising_detected_stage2 <= rising_detected_stage1;
            pulse_active_stage2 <= pulse_active_stage1;
            busy_decoding_stage2 <= busy_decoding_stage1;
            pwm_in_reg_stage2 <= pwm_in_reg_stage1;
            pwm_in_prev_stage2 <= pwm_in_prev_stage1;
        end
    end
    
    // PWM decoder pipeline - Stage 3: Combine capture value
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            capture_combined_stage3 <= 8'h00;
            rising_detected_stage3 <= 1'b0;
            pulse_active_stage3 <= 1'b0;
            busy_decoding_stage3 <= 1'b0;
        end else begin
            capture_combined_stage3 <= {capture_high_stage2, capture_low_stage2};
            rising_detected_stage3 <= rising_detected_stage2;
            pulse_active_stage3 <= pulse_active_stage2;
            busy_decoding_stage3 <= busy_decoding_stage2;
        end
    end
    
    // PWM decoder pipeline - Stage 4: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            duty_out <= 8'h00;
            duty_out_valid <= 1'b0;
            duty_ready_to_clear <= 1'b0;
        end else begin
            // Generate output when decoding is complete
            if (busy_decoding_stage3 && !pulse_active_stage3 && rising_detected_stage3) begin
                duty_out <= capture_combined_stage3;
                duty_out_valid <= 1'b1;
            end
            
            // Handle handshaking
            if (duty_out_valid && duty_out_ready) begin
                duty_ready_to_clear <= 1'b1;
            end
            
            if (duty_ready_to_clear) begin
                duty_out_valid <= 1'b0;
                duty_ready_to_clear <= 1'b0;
            end
        end
    end
endmodule