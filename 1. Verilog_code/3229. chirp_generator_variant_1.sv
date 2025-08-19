//SystemVerilog
module chirp_generator(
    input clk,
    input rst,
    input [15:0] start_freq,
    input [15:0] freq_step,
    input [7:0] step_interval,
    output reg [7:0] chirp_out
);
    // Stage 1 registers
    reg [15:0] freq_stage1;
    reg [15:0] phase_acc_stage1;
    reg [7:0] interval_counter_stage1;
    
    // Stage 2 registers
    reg [15:0] freq_stage2;
    reg [15:0] phase_acc_stage2;
    reg [7:0] interval_counter_stage2;
    reg [1:0] quadrant_stage2;
    reg [6:0] phase_value_stage2;
    
    // Stage 3 registers
    reg [15:0] freq_stage3;
    reg [7:0] interval_counter_stage3;
    reg [7:0] sine_value_stage3;
    
    // Pipeline Stage 1: Frequency and phase accumulation
    always @(posedge clk) begin
        if (rst) begin
            freq_stage1 <= start_freq;
            phase_acc_stage1 <= 16'd0;
            interval_counter_stage1 <= 8'd0;
        end else begin
            // Phase accumulation based on current frequency
            phase_acc_stage1 <= phase_acc_stage1 + freq_stage1;
            
            // Optimized frequency stepping logic with single comparison
            interval_counter_stage1 <= (interval_counter_stage1 == step_interval) ? 8'd0 : interval_counter_stage1 + 8'd1;
            freq_stage1 <= (interval_counter_stage1 == step_interval) ? freq_stage1 + freq_step : freq_stage1;
        end
    end
    
    // Pipeline Stage 2: Quadrant calculation and preparation
    always @(posedge clk) begin
        if (rst) begin
            phase_acc_stage2 <= 16'd0;
            freq_stage2 <= start_freq;
            interval_counter_stage2 <= 8'd0;
            quadrant_stage2 <= 2'b00;
            phase_value_stage2 <= 7'd0;
        end else begin
            // Pass through values for next stage
            phase_acc_stage2 <= phase_acc_stage1;
            freq_stage2 <= freq_stage1;
            interval_counter_stage2 <= interval_counter_stage1;
            
            // Extract quadrant and phase value directly from phase accumulator
            quadrant_stage2 <= phase_acc_stage1[15:14];
            phase_value_stage2 <= phase_acc_stage1[13:7];
        end
    end
    
    // Pipeline Stage 3: Sine approximation calculation with optimized logic
    reg [7:0] phase_val_extended;
    
    always @(posedge clk) begin
        if (rst) begin
            freq_stage3 <= start_freq;
            interval_counter_stage3 <= 8'd0;
            sine_value_stage3 <= 8'd128;
        end else begin
            // Pass through values for next stage if needed
            freq_stage3 <= freq_stage2;
            interval_counter_stage3 <= interval_counter_stage2;
            
            // Pre-compute extended phase value to avoid repeated concatenation
            phase_val_extended = {1'b0, phase_value_stage2};
            
            // Optimized sine approximation using quadrant without case statement
            sine_value_stage3 <= quadrant_stage2[1] ? 
                                (quadrant_stage2[0] ? phase_val_extended : 8'd127 - phase_val_extended) :
                                (quadrant_stage2[0] ? 8'd255 - phase_val_extended : 8'd128 + phase_val_extended);
        end
    end
    
    // Output stage with direct assignment
    always @(posedge clk) begin
        chirp_out <= rst ? 8'd128 : sine_value_stage3;
    end
endmodule