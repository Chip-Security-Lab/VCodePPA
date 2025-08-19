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
    reg [COUNTER_WIDTH-1:0] counter;
    reg [COUNTER_WIDTH-1:0] period_reg;
    reg [COUNTER_WIDTH-1:0] deadtime_reg;
    reg [COUNTER_WIDTH-1:0] half_period_minus_deadtime;
    reg [COUNTER_WIDTH-1:0] half_period_plus_deadtime;
    
    // Register inputs to improve timing at input stage
    always @(posedge clock) begin
        if (reset) begin
            period_reg <= {COUNTER_WIDTH{1'b0}};
            deadtime_reg <= {COUNTER_WIDTH{1'b0}};
        end else begin
            period_reg <= period;
            deadtime_reg <= deadtime;
        end
    end
    
    // Pre-compute comparison values
    always @(posedge clock) begin
        if (reset) begin
            half_period_minus_deadtime <= {COUNTER_WIDTH{1'b0}};
            half_period_plus_deadtime <= {COUNTER_WIDTH{1'b0}};
        end else begin
            half_period_minus_deadtime <= (period_reg >> 1) - deadtime_reg;
            half_period_plus_deadtime <= (period_reg >> 1) + deadtime_reg;
        end
    end
    
    // Counter logic
    always @(posedge clock) begin
        if (reset) begin
            counter <= {COUNTER_WIDTH{1'b0}};
        end else begin
            if (counter >= period_reg - 1'b1) begin
                counter <= {COUNTER_WIDTH{1'b0}};
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
    
    // Output signal generation with simplified comparison logic
    always @(posedge clock) begin
        if (reset) begin
            signal_a <= 1'b0;
            signal_b <= 1'b0;
        end else begin
            // First half of period minus deadtime
            if (counter < half_period_minus_deadtime) begin
                signal_a <= 1'b1;
                signal_b <= 1'b0;
            // Second half of period minus deadtime
            end else if (counter >= half_period_plus_deadtime) begin
                signal_a <= 1'b0;
                signal_b <= 1'b1;
            // Deadband region
            end else begin
                signal_a <= 1'b0;
                signal_b <= 1'b0;
            end
        end
    end
endmodule