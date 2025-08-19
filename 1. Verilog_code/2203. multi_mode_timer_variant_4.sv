//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
module multi_mode_timer #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire [1:0] mode,
    input wire [WIDTH-1:0] period,
    output reg out
);
    // Stage 1: Counter and comparison logic
    reg [WIDTH-1:0] counter_stage1;
    reg [WIDTH-1:0] period_stage1;
    reg [1:0] mode_stage1;
    reg out_stage1;
    
    // Stage 2: Mode-specific output logic
    reg [WIDTH-1:0] counter_stage2;
    reg [WIDTH-1:0] period_stage2;
    reg [1:0] mode_stage2;
    reg out_stage2;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2;
    
    // Comparison results for pipelining
    reg counter_lt_period_stage1;
    reg counter_lt_half_period_stage1;
    reg counter_eq_period_minus1_stage1;
    
    // Stage 1: Counter management and comparisons
    always @(posedge clk) begin
        if (rst) begin
            counter_stage1 <= {WIDTH{1'b0}};
            period_stage1 <= {WIDTH{1'b0}};
            mode_stage1 <= 2'b00;
            out_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            
            counter_lt_period_stage1 <= 1'b0;
            counter_lt_half_period_stage1 <= 1'b0;
            counter_eq_period_minus1_stage1 <= 1'b0;
        end else begin
            // Register inputs for stage 1
            period_stage1 <= period;
            mode_stage1 <= mode;
            valid_stage1 <= 1'b1;
            out_stage1 <= out;
            
            // Counter update logic converted from case to if-else
            if (mode == 2'd0) begin // One-Shot Mode
                if (counter_stage1 < period_stage1) begin
                    counter_stage1 <= counter_stage1 + 1'b1;
                end
            end else if (mode == 2'd1 || mode == 2'd2 || mode == 2'd3) begin // Periodic, PWM, Toggle Modes
                if (counter_stage1 >= period_stage1 - 1) begin
                    counter_stage1 <= {WIDTH{1'b0}};
                end else begin
                    counter_stage1 <= counter_stage1 + 1'b1;
                end
            end
            
            // Pre-compute comparisons for next stage
            counter_lt_period_stage1 <= counter_stage1 < period_stage1;
            counter_lt_half_period_stage1 <= counter_stage1 < (period_stage1 >> 1);
            counter_eq_period_minus1_stage1 <= counter_stage1 >= period_stage1 - 1;
        end
    end
    
    // Stage 2: Output determination based on mode and comparison results
    always @(posedge clk) begin
        if (rst) begin
            counter_stage2 <= {WIDTH{1'b0}};
            period_stage2 <= {WIDTH{1'b0}};
            mode_stage2 <= 2'b00;
            out_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            out <= 1'b0;
        end else if (valid_stage1) begin
            // Register stage 1 values for stage 2
            counter_stage2 <= counter_stage1;
            period_stage2 <= period_stage1;
            mode_stage2 <= mode_stage1;
            valid_stage2 <= valid_stage1;
            
            // Mode-specific output logic using pre-computed comparisons
            // Converted from case to if-else
            if (mode_stage1 == 2'd0) begin // One-Shot Mode
                out_stage2 <= counter_lt_period_stage1 ? 1'b1 : 1'b0;
            end else if (mode_stage1 == 2'd1) begin // Periodic Mode
                out_stage2 <= counter_eq_period_minus1_stage1 ? 1'b1 : 1'b0;
            end else if (mode_stage1 == 2'd2) begin // PWM Mode (50% duty)
                out_stage2 <= counter_lt_half_period_stage1 ? 1'b1 : 1'b0;
            end else if (mode_stage1 == 2'd3) begin // Toggle Mode
                if (counter_eq_period_minus1_stage1) begin
                    out_stage2 <= ~out_stage1;
                end else begin
                    out_stage2 <= out_stage1;
                end
            end
            
            // Final output assignment
            if (valid_stage2) begin
                out <= out_stage2;
            end
        end
    end
endmodule