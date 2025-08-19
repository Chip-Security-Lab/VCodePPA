//SystemVerilog
module deadband_generator #(
    parameter COUNTER_WIDTH = 10
)(
    input wire clock,
    input wire reset,
    input wire [COUNTER_WIDTH-1:0] period,
    input wire [COUNTER_WIDTH-1:0] deadtime,
    output reg signal_a,
    output reg signal_b
);
    // Stage 1: Counter logic
    reg [COUNTER_WIDTH-1:0] counter;
    reg counter_reset_stage1;
    reg valid_stage1;
    
    // Pipeline registers for threshold calculation
    reg [COUNTER_WIDTH-1:0] period_reg;
    reg [COUNTER_WIDTH-1:0] deadtime_reg;
    reg [COUNTER_WIDTH-1:0] half_period; // Intermediate register for period >> 1
    
    // Stage 2: Threshold calculation
    reg [COUNTER_WIDTH-1:0] threshold_lower_stage2;
    reg [COUNTER_WIDTH-1:0] threshold_upper_stage2;
    reg [COUNTER_WIDTH-1:0] counter_stage2;
    reg valid_stage2;
    
    // Stage 3: Region comparison
    reg [COUNTER_WIDTH-1:0] counter_stage3;
    reg [COUNTER_WIDTH-1:0] threshold_lower_stage3;
    reg [COUNTER_WIDTH-1:0] threshold_upper_stage3;
    reg lower_region_stage3;
    reg upper_region_stage3;
    reg deadband_region_stage3;
    reg valid_stage3;
    
    // Stage 4: Output signal generation
    reg signal_a_next;
    reg signal_b_next;
    
    // Stage 1: Counter management and input registration
    always @(posedge clock) begin
        if (reset) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            counter_reset_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            period_reg <= {COUNTER_WIDTH{1'b0}};
            deadtime_reg <= {COUNTER_WIDTH{1'b0}};
        end else begin
            valid_stage1 <= 1'b1;
            
            // Register inputs to improve timing
            period_reg <= period;
            deadtime_reg <= deadtime;
            
            // Counter logic
            if (counter >= period_reg - 1'b1) begin
                counter <= {COUNTER_WIDTH{1'b0}};
                counter_reset_stage1 <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
                counter_reset_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 1.5: Half period calculation (splitting the critical path)
    always @(posedge clock) begin
        if (reset) begin
            half_period <= {COUNTER_WIDTH{1'b0}};
        end else begin
            half_period <= period_reg >> 1;
        end
    end
    
    // Stage 2: Threshold calculation
    always @(posedge clock) begin
        if (reset) begin
            threshold_lower_stage2 <= {COUNTER_WIDTH{1'b0}};
            threshold_upper_stage2 <= {COUNTER_WIDTH{1'b0}};
            counter_stage2 <= {COUNTER_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            counter_stage2 <= counter;
            
            // Split calculation of thresholds to reduce path length
            threshold_lower_stage2 <= half_period - deadtime_reg;
            threshold_upper_stage2 <= half_period + deadtime_reg;
        end
    end
    
    // Stage 3: Region comparison
    always @(posedge clock) begin
        if (reset) begin
            counter_stage3 <= {COUNTER_WIDTH{1'b0}};
            threshold_lower_stage3 <= {COUNTER_WIDTH{1'b0}};
            threshold_upper_stage3 <= {COUNTER_WIDTH{1'b0}};
            lower_region_stage3 <= 1'b0;
            upper_region_stage3 <= 1'b0;
            deadband_region_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            
            // Pass values to stage 3
            counter_stage3 <= counter_stage2;
            threshold_lower_stage3 <= threshold_lower_stage2;
            threshold_upper_stage3 <= threshold_upper_stage2;
            
            // Determine which region we're in
            lower_region_stage3 <= (counter_stage2 < threshold_lower_stage2);
            upper_region_stage3 <= (counter_stage2 >= threshold_upper_stage2);
            // Avoid complex expression with &&, use property: if not lower and not upper, must be deadband
            deadband_region_stage3 <= !(counter_stage2 < threshold_lower_stage2) && 
                                      !(counter_stage2 >= threshold_upper_stage2);
        end
    end
    
    // Stage 4: Signal generation
    always @(posedge clock) begin
        if (reset) begin
            signal_a <= 1'b0;
            signal_b <= 1'b0;
            signal_a_next <= 1'b0;
            signal_b_next <= 1'b0;
        end else if (valid_stage3) begin
            // Simple priority-based output signal generation to reduce logic depth
            if (lower_region_stage3) begin
                signal_a_next <= 1'b1;
                signal_b_next <= 1'b0;
            end else if (upper_region_stage3) begin
                signal_a_next <= 1'b0;
                signal_b_next <= 1'b1;
            end else begin // deadband_region_stage3
                signal_a_next <= 1'b0;
                signal_b_next <= 1'b0;
            end
            
            // Update output registers
            signal_a <= signal_a_next;
            signal_b <= signal_b_next;
        end
    end
endmodule