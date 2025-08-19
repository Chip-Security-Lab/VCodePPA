//SystemVerilog
//IEEE 1364-2005 Verilog
module pwm_codec (
    input wire clk, rst_n, 
    input wire [7:0] duty_in,    // For encoding
    input wire pwm_in,           // For decoding
    output reg pwm_out,          // Encoded PWM signal
    output reg [7:0] duty_out,   // Decoded duty cycle
    output reg valid_duty        // Valid decoded value
);
    // Pipeline stage registers
    reg [7:0] counter_stage1, counter_stage2;
    reg [7:0] duty_in_stage1, duty_in_stage2;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // PWM decoder signals
    reg [7:0] capture;
    reg rising_detected, pulse_active;
    reg pwm_in_prev;
    
    // Carry-skip adder pipeline stage signals
    reg [8:0] carry; // 9-bit carry for 8-bit addition
    wire [7:0] sum;
    wire [1:0] block_prop; // Block propagate signals for carry-skip
    
    // Block propagate calculation for carry-skip adder
    assign block_prop[0] = &counter_stage1[3:0]; // AND of bits 0-3
    assign block_prop[1] = &counter_stage1[7:4]; // AND of bits 4-7
    
    // Sum calculation using XOR
    assign sum[0] = counter_stage1[0] ^ carry[0];
    assign sum[1] = counter_stage1[1] ^ carry[1];
    assign sum[2] = counter_stage1[2] ^ carry[2];
    assign sum[3] = counter_stage1[3] ^ carry[3];
    assign sum[4] = counter_stage1[4] ^ carry[4];
    assign sum[5] = counter_stage1[5] ^ carry[5];
    assign sum[6] = counter_stage1[6] ^ carry[6];
    assign sum[7] = counter_stage1[7] ^ carry[7];
    
    // First pipeline stage - Input registration and initial carry processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1 <= 8'h00;
            duty_in_stage1 <= 8'h00;
            carry[0] <= 1'b1; // Initial carry-in for increment
            valid_stage1 <= 1'b0;
        end else begin
            // Register inputs
            counter_stage1 <= counter_stage2;
            duty_in_stage1 <= duty_in;
            valid_stage1 <= 1'b1;
            
            // Initial carry-in for increment operation
            carry[0] <= 1'b1;
            
            // Regular carry generation for first 4 bits
            carry[1] <= counter_stage1[0] & carry[0];
            carry[2] <= counter_stage1[1] & carry[1];
            carry[3] <= counter_stage1[2] & carry[2];
            carry[4] <= (counter_stage1[3] & carry[3]) | 
                         (block_prop[0] & carry[0]); // Skip carry for first block
        end
    end
    
    // Second pipeline stage - Higher bit carries and sum calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            duty_in_stage2 <= 8'h00;
            counter_stage2 <= 8'h00;
            valid_stage2 <= 1'b0;
        end else begin
            duty_in_stage2 <= duty_in_stage1;
            valid_stage2 <= valid_stage1;
            
            // Higher bits carry calculation with carry-skip
            carry[5] <= counter_stage1[4] & carry[4];
            carry[6] <= counter_stage1[5] & carry[5];
            carry[7] <= counter_stage1[6] & carry[6];
            carry[8] <= (counter_stage1[7] & carry[7]) | 
                         (block_prop[1] & carry[4]); // Skip carry for second block
            
            // Update counter for next cycle
            counter_stage2 <= sum;
        end
    end
    
    // Final pipeline stage - Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_out <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            // Generate PWM output based on duty cycle
            pwm_out <= (counter_stage2 < duty_in_stage2) ? 1'b1 : 1'b0;
        end
    end
    
    // PWM decoder (measures duty cycle) with pipelined approach
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            capture <= 8'h00;
            duty_out <= 8'h00;
            rising_detected <= 1'b0;
            pulse_active <= 1'b0;
            pwm_in_prev <= 1'b0;
            valid_duty <= 1'b0;
        end else begin
            // Store previous value for edge detection
            pwm_in_prev <= pwm_in;
            
            // Rising edge detection
            if (pwm_in && !pwm_in_prev) begin
                pulse_active <= 1'b1;
                capture <= 8'h00;
                rising_detected <= 1'b0;
            end 
            // Falling edge detection
            else if (!pwm_in && pwm_in_prev && pulse_active) begin
                duty_out <= capture;
                pulse_active <= 1'b0;
                rising_detected <= 1'b1;
                valid_duty <= 1'b1;
            end
            // During active pulse, increment capture counter
            else if (pulse_active) begin
                capture <= capture + 1'b1;
                valid_duty <= 1'b0;
            end
            else begin
                rising_detected <= 1'b0;
                valid_duty <= 1'b0;
            end
        end
    end
endmodule